//
//  MotionRecorder.swift
//  GaitBAC
//

import Foundation
import SwiftUI
import CoreMotion
import AVFoundation
import UIKit

final class MotionRecorder: ObservableObject {

    enum State { case idle, countingDown, recording, paused, finished }

    // Published on main thread only
    @Published var state: State = .idle
    @Published var measuredHz: Double = 0
    @Published var avgAccelNorm: Double = 0
    @Published var estCadenceSpm: Double = 0
    @Published var elapsed: Double = 0

    // Config / runtime
    private let motion = CMMotionManager()
    private let motionQueue: OperationQueue = {
        let q = OperationQueue()
        q.name = "motion.queue"
        q.qualityOfService = .userInitiated
        q.maxConcurrentOperationCount = 1
        return q
    }()

    private var samples: [SensorSample] = []
    private var t0Sample: TimeInterval?        // time of first sample (relative)
    private var targetHz: Int = 100
    private var beeps: Bool = true

    // Timers
    private var displayLink: CADisplayLink?
    private var capTimer: DispatchSourceTimer?
    private var tick30sTimer: DispatchSourceTimer?

    // Rolling stats
    private var accelNormWindow: [Double] = []
    private var timeWindow: [Double] = []

    // Constants
    private let capSeconds: Int = 360 // 6 minutes hard cap

    // MARK: - Public API

    /// Prepare for a new session. Duration is deprecated (kept for back-compat).
    func prepare(targetHz: Int, durationSec: Int = 0, prerollSec: Double = 2.0, beeps: Bool = true, haptics _: Bool = false) {
        self.targetHz = targetHz
        self.beeps = beeps

        // Reset on main
        DispatchQueue.main.async {
            self.samples.removeAll(keepingCapacity: true)
            self.t0Sample = nil
            self.measuredHz = 0
            self.avgAccelNorm = 0
            self.estCadenceSpm = 0
            self.elapsed = 0
            self.accelNormWindow.removeAll()
            self.timeWindow.removeAll()
            self.invalidateAllTimers()
            self.state = .idle
        }
    }

    /// Start device motion acquisition. `withGoAt` kept for compatibility (not used internally).
    func startRecording(withGoAt _: Date) {
        guard motion.isDeviceMotionAvailable else { return }

        // Begin recording
        DispatchQueue.main.async { self.state = .recording }

        // Configure and start motion updates
        motion.deviceMotionUpdateInterval = 1.0 / Double(max(1, targetHz))
        motion.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: motionQueue) { [weak self] dm, err in
            guard let self = self else { return }
            if let dm {
                let sample = self.makeSample(from: dm)
                let norm = self.magnitude(ax: sample.ax, ay: sample.ay, az: sample.az)

                // Main thread publication
                DispatchQueue.main.async {
                    guard self.state == .recording || self.state == .paused else { return }
                    if self.t0Sample == nil { self.t0Sample = sample.t }
                    self.samples.append(sample)

                    // Live stats with a 5s window
                    self.timeWindow.append(sample.t)
                    self.accelNormWindow.append(norm)
                    while let first = self.timeWindow.first, sample.t - first > 5 {
                        _ = self.timeWindow.removeFirst()
                        _ = self.accelNormWindow.removeFirst()
                    }
                    let count = max(1, self.accelNormWindow.count)
                    self.avgAccelNorm = self.accelNormWindow.reduce(0, +) / Double(count)
                    self.estCadenceSpm = self.estimateCadenceSPM(times: self.timeWindow, values: self.accelNormWindow)

                    // Precise elapsed from first sample
                    self.elapsed = max(0, sample.t - (self.t0Sample ?? sample.t))
                }
            } else if err != nil {
                DispatchQueue.main.async { self._stopRecordingMain() }
            }
        }

        // UI elapsed updater
        startElapsedDisplayLink()

        // 6-minute cap
        scheduleCapTimer()

        // 30s tick beeps (non-blocking)
        schedule30sTicks()
    }

    func stopRecording() {
        if Thread.isMainThread { _stopRecordingMain() }
        else { DispatchQueue.main.async { self._stopRecordingMain() } }
    }

    func pause() {
        guard state == .recording else { return }
        motion.stopDeviceMotionUpdates()
        stopElapsedDisplayLink()
        DispatchQueue.main.async { self.state = .paused }
    }

    func resume() {
        guard state == .paused else { return }
        DispatchQueue.main.async { self.state = .recording }

        motion.deviceMotionUpdateInterval = 1.0 / Double(max(1, targetHz))
        motion.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: motionQueue) { [weak self] dm, err in
            guard let self = self else { return }
            if let dm {
                let sample = self.makeSample(from: dm)
                let norm = self.magnitude(ax: sample.ax, ay: sample.ay, az: sample.az)

                DispatchQueue.main.async {
                    guard self.state == .recording else { return }
                    if self.t0Sample == nil { self.t0Sample = sample.t }
                    self.samples.append(sample)
                    self.timeWindow.append(sample.t)
                    self.accelNormWindow.append(norm)
                    while let first = self.timeWindow.first, sample.t - first > 5 {
                        _ = self.timeWindow.removeFirst()
                        _ = self.accelNormWindow.removeFirst()
                    }
                    self.avgAccelNorm = self.accelNormWindow.reduce(0, +) / Double(max(1, self.accelNormWindow.count))
                    self.estCadenceSpm = self.estimateCadenceSPM(times: self.timeWindow, values: self.accelNormWindow)
                    self.elapsed = max(0, sample.t - (self.t0Sample ?? sample.t))
                }
            } else if err != nil {
                DispatchQueue.main.async { self._stopRecordingMain() }
            }
        }

        startElapsedDisplayLink()
    }

    func export(meta: SessionMeta, settings: AppSettings) -> (URL, QualitySummary)? {
        let quality = computeQuality(samples: samples, targetHz: targetHz)
        var m = meta
        m.sampling_hz_measured = quality.measuredHz
        m.duration_recorded_s = quality.durationReal
        do {
            let url = try CSVWriter.writeSessionCSV(meta: m, samples: samples, settings: settings, quality: quality)
            return (url, quality)
        } catch {
            print("CSV write error: \(error)")
            return nil
        }
    }

    func discard() {
        DispatchQueue.main.async {
            self.motion.stopDeviceMotionUpdates()
            self.invalidateAllTimers()
            self.samples.removeAll(keepingCapacity: true)
            self.t0Sample = nil
            self.elapsed = 0
            self.state = .idle
        }
    }

    // MARK: - Internals

    private func _stopRecordingMain() {
        motion.stopDeviceMotionUpdates()
        invalidateAllTimers()

        if samples.count > 1 {
            let t0 = samples.first!.t, tN = samples.last!.t
            let dur = max(tN - t0, 1e-6)
            measuredHz = Double(samples.count - 1) / dur
            elapsed = dur
        }
        state = .finished
        print("[Recorder] finished - samples=\(samples.count) measuredHz=\(measuredHz)")
    }

    private func startElapsedDisplayLink() {
        DispatchQueue.main.async {
            self.displayLink?.invalidate()
            self.displayLink = CADisplayLink(target: self, selector: #selector(self._uiTick))
            self.displayLink?.add(to: .main, forMode: .common)
        }
    }

    private func stopElapsedDisplayLink() {
        DispatchQueue.main.async {
            self.displayLink?.invalidate()
            self.displayLink = nil
        }
    }

    @objc private func _uiTick() {
        // Elapsed is updated from samples; no-op here to keep DisplayLink alive for UI refresh
    }

    private func scheduleCapTimer() {
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + .seconds(capSeconds))
        timer.setEventHandler { [weak self] in
            guard let self, self.state == .recording else { return }
            self._stopRecordingMain()
        }
        capTimer = timer
        timer.resume()
    }

    private func schedule30sTicks() {
        guard beeps else { return }
        let timer = DispatchSource.makeTimerSource(queue: .main)
        // Start at next 30s boundary: 30, 60, ..., 360
        timer.schedule(deadline: .now() + .seconds(30), repeating: .seconds(30))
        timer.setEventHandler {
            // Only while recording; last tick at 6:00 inclusive
            if self.state == .recording {
                AudioManager.beepShort()
            }
        }
        tick30sTimer = timer
        timer.resume()
    }

    private func invalidateAllTimers() {
        displayLink?.invalidate(); displayLink = nil
        capTimer?.cancel(); capTimer = nil
        tick30sTimer?.cancel(); tick30sTimer = nil
    }

    private func makeSample(from dm: CMDeviceMotion) -> SensorSample {
        let a = dm.userAcceleration
        let r = dm.rotationRate
        let q = dm.attitude.quaternion
        let g = dm.gravity
        let t = dm.timestamp // seconds since boot (monotonic)
        return SensorSample(
            t: t,
            ax: a.x, ay: a.y, az: a.z,
            gx: r.x, gy: r.y, gz: r.z,
            qw: q.w, qx: q.x, qy: q.y, qz: q.z,
            gravx: g.x, gravy: g.y, gravz: g.z,
            actType: nil
        )
    }

    private func magnitude(ax: Double, ay: Double, az: Double) -> Double {
        sqrt(ax*ax + ay*ay + az*az)
    }

    private func computeQuality(samples: [SensorSample], targetHz: Int) -> QualitySummary {
        guard samples.count >= 3 else {
            return .init(measuredHz: 0, droppedPct: 100, durationReal: 0, cadenceSpm: nil, accelMedianNorm: nil, score: "Mauvaise qualité")
        }
        let t0 = samples.first!.t, tN = samples.last!.t
        let dur = max(tN - t0, 1e-6)
        let measured = Double(samples.count - 1) / dur

        let expectedDt = 1.0 / Double(targetHz)
        var dropped = 0, totalSlots = 0
        var lastT = samples[0].t
        for i in 1..<samples.count {
            let dt = samples[i].t - lastT
            let slots = Int((dt / expectedDt).rounded())
            totalSlots += max(1, slots)
            if dt > 1.5 * expectedDt { dropped += max(0, slots - 1) }
            lastT = samples[i].t
        }
        let droppedPct = totalSlots > 0 ? (100.0 * Double(dropped) / Double(totalSlots)) : 0.0

        let norms = samples.map { sqrt($0.ax*$0.ax + $0.ay*$0.ay + $0.az*$0.az) }
        let median = norms.sorted()[norms.count/2]
        let times = samples.map { $0.t }
        let cadence = estimateCadenceSPM(times: times, values: norms)

        var score = "OK"
        if abs(measured - Double(targetHz)) / Double(targetHz) > 0.10 { score = "Attention" }
        if droppedPct > 2.0 { score = "Attention" }
        if !(0.5...3.0).contains(median) { score = "Attention" }
        if cadence != 0, !(80...140).contains(cadence) { score = "Attention" }

        return .init(measuredHz: measured, droppedPct: droppedPct, durationReal: dur,
                     cadenceSpm: cadence == 0 ? nil : cadence, accelMedianNorm: median, score: score)
    }

    /// Very-light cadence estimate from a magnitude stream (placeholder; same as your original heuristic)
    private func estimateCadenceSPM(times: [Double], values: [Double]) -> Double {
        guard times.count > 8, values.count == times.count else { return 0 }
        // Zero-crossing-like rough estimate: count peaks above median+std within a sliding window
        let n = values.count
        let mean = values.reduce(0,+)/Double(n)
        let std = sqrt(values.map{ ($0 - mean)*($0 - mean) }.reduce(0,+)/Double(n))
        let th = mean + 0.5*std
        var peaks = 0
        for i in 1..<(n-1) {
            if values[i] > th && values[i] > values[i-1] && values[i] > values[i+1] { peaks += 1 }
        }
        let duration = max(1e-6, (times.last! - times.first!))
        let stepsPerSec = Double(peaks)/duration
        return stepsPerSec * 60.0
    }
}
