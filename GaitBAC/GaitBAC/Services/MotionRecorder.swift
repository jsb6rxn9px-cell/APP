//
//  MotionRecorder.swift
//  GaitBAC
//
//  Created by Hugo Roy-Poulin on 2025-09-15.
//

import Foundation
import SwiftUI
import CoreMotion
import UIKit

final class MotionRecorder: ObservableObject {
    enum State { case idle, countingDown, recording, paused, finished }

    // Toutes ces propriétés seront mises à jour sur le MAIN
    @Published var state: State = .idle
    @Published var measuredHz: Double = 0
    @Published var avgAccelNorm: Double = 0
    @Published var estCadenceSpm: Double = 0
    @Published var elapsed: Double = 0

    private let motion = CMMotionManager()
    private let motionQueue: OperationQueue = {
        let q = OperationQueue()
        q.name = "motion.queue"
        q.qualityOfService = .userInitiated
        q.maxConcurrentOperationCount = 1
        return q
    }()

    private var samples: [SensorSample] = []
    private var tBaseline: TimeInterval?

    private var targetHz: Int = 100
    private var durationSec: Int = 30
    private var beeps: Bool = true
    private var haptics: Bool = true

    private var displayLink: CADisplayLink?
    private var safetyStopWorkItem: DispatchWorkItem?

    private var accelNormWindow: [Double] = []
    private var timeWindow: [Double] = []

    // MARK: - Public API

    func prepare(targetHz: Int, durationSec: Int, prerollSec: Double = 2.0, beeps: Bool, haptics: Bool) {
        self.targetHz = targetHz
        self.durationSec = durationSec
        self.beeps = beeps
        self.haptics = haptics

        // Reset côté MAIN
        DispatchQueue.main.async {
            self.samples.removeAll(keepingCapacity: true)
            self.tBaseline = nil
            self.measuredHz = 0
            self.avgAccelNorm = 0
            self.estCadenceSpm = 0
            self.elapsed = 0
            self.accelNormWindow.removeAll()
            self.timeWindow.removeAll()
            self.state = .idle
        }
    }

    func startRecording(withGoAt _: Date) {
        guard motion.isDeviceMotionAvailable else { return }

        DispatchQueue.main.async { self.state = .recording }

        samples.removeAll(keepingCapacity: true)
        tBaseline = nil
        accelNormWindow.removeAll()
        timeWindow.removeAll()

        motion.deviceMotionUpdateInterval = 1.0 / Double(targetHz)

        // Handler sur queue dédiée, mais on PUBLIE sur MAIN
        motion.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: motionQueue) { [weak self] dm, error in
            guard let self = self else { return }

            if let dm {
                // Calculs rapides en background
                let sample = self.makeSample(from: dm)
                let norm = self.magnitude(ax: sample.ax, ay: sample.ay, az: sample.az)
                let t = sample.t

                // Publication sur le MAIN (samples, elapsed, stats, etc.)
                DispatchQueue.main.async {
                    // Si on a quitté l’enregistrement entre-temps, ignorer
                    guard self.state == .recording || self.state == .paused else { return }

                    self.samples.append(sample)

                    // Stats live (fenêtre 5 s)
                    self.accelNormWindow.append(norm)
                    self.timeWindow.append(t)
                    while let first = self.timeWindow.first, t - first > 5 {
                        _ = self.timeWindow.removeFirst()
                        _ = self.accelNormWindow.removeFirst()
                    }
                    self.avgAccelNorm = self.accelNormWindow.reduce(0, +) / max(1, Double(self.accelNormWindow.count))
                    self.estCadenceSpm = self.estimateCadenceSPM(times: self.timeWindow, values: self.accelNormWindow)

                    self.elapsed = t

                    // Arrêt immédiat au-delà de la durée
                    if t >= Double(self.durationSec), self.state == .recording {
                        self._stopRecordingMain()
                    }
                }
            } else if error != nil {
                DispatchQueue.main.async {
                    self._stopRecordingMain()
                }
            }
        }

        startElapsedTimer()

        // Garde-fou : durée + 5 s
        safetyStopWorkItem?.cancel()
        let wi = DispatchWorkItem { [weak self] in
            guard let self, self.state == .recording else { return }
            self._stopRecordingMain()
        }
        safetyStopWorkItem = wi
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(durationSec + 5), execute: wi)
    }

    func stopRecording() {
        // Toujours arrêter côté MAIN
        if Thread.isMainThread { _stopRecordingMain() }
        else { DispatchQueue.main.async { self._stopRecordingMain() } }
    }

    func pause() {
        guard state == .recording else { return }
        motion.stopDeviceMotionUpdates()
        stopElapsedTimer()
        DispatchQueue.main.async { self.state = .paused }
    }

    func resume() {
        guard state == .paused else { return }
        DispatchQueue.main.async { self.state = .recording }

        motion.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: motionQueue) { [weak self] dm, error in
            guard let self = self else { return }
            if let dm {
                let sample = self.makeSample(from: dm)
                let norm = self.magnitude(ax: sample.ax, ay: sample.ay, az: sample.az)
                let t = sample.t
                DispatchQueue.main.async {
                    guard self.state == .recording else { return }
                    self.samples.append(sample)
                    self.accelNormWindow.append(norm); self.timeWindow.append(t)
                    while let first = self.timeWindow.first, t - first > 5 {
                        _ = self.timeWindow.removeFirst(); _ = self.accelNormWindow.removeFirst()
                    }
                    self.avgAccelNorm = self.accelNormWindow.reduce(0, +) / max(1, Double(self.accelNormWindow.count))
                    self.estCadenceSpm = self.estimateCadenceSPM(times: self.timeWindow, values: self.accelNormWindow)
                    self.elapsed = t
                }
            } else if error != nil {
                DispatchQueue.main.async { self._stopRecordingMain() }
            }
        }

        startElapsedTimer()
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

    // Pour reset total (utilisé lors des retours Home/Consent)
    func discard() {
        motion.stopDeviceMotionUpdates()
        stopElapsedTimer()
        safetyStopWorkItem?.cancel(); safetyStopWorkItem = nil

        DispatchQueue.main.async {
            self.samples.removeAll()
            self.tBaseline = nil
            self.measuredHz = 0
            self.avgAccelNorm = 0
            self.estCadenceSpm = 0
            self.elapsed = 0
            self.state = .idle
        }
    }

    // MARK: - Private (MAIN-safe)

    private func _stopRecordingMain() {
        // Toujours MAIN ici
        motion.stopDeviceMotionUpdates()
        stopElapsedTimer()
        safetyStopWorkItem?.cancel(); safetyStopWorkItem = nil

        if samples.count > 1 {
            let t0 = samples.first!.t, tN = samples.last!.t
            let dur = max(tN - t0, 1e-6)
            measuredHz = Double(samples.count - 1) / dur
        }
        state = .finished
        print("[Recorder] finished - samples=\(samples.count) measuredHz=\(measuredHz)")
        if haptics { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        
        
    }

    private func startElapsedTimer() {
        DispatchQueue.main.async {
            self.displayLink?.invalidate()
            self.displayLink = CADisplayLink(target: self, selector: #selector(self.tick))
            self.displayLink?.add(to: .main, forMode: .common)
        }
    }

    private func stopElapsedTimer() {
        DispatchQueue.main.async {
            self.displayLink?.invalidate()
            self.displayLink = nil
        }
    }

    @objc private func tick() {
        // elapsed déjà mis à jour côté MAIN par le handler;
        // garde-fou ici au cas où
        if elapsed >= Double(durationSec), state == .recording {
            _stopRecordingMain()
        }
    }

    private func makeSample(from dm: CMDeviceMotion) -> SensorSample {
        if tBaseline == nil { tBaseline = dm.timestamp }
        let t = dm.timestamp - (tBaseline ?? dm.timestamp)
        let a = dm.userAcceleration
        let g = dm.gravity
        let r = dm.rotationRate
        let q = dm.attitude.quaternion
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
        let droppedPct = totalSlots > 0 ? 100.0 * Double(dropped) / Double(totalSlots) : 0

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

    private func estimateCadenceSPM(times: [Double], values: [Double]) -> Double {
        guard times.count > 8 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(values.count)
        let std = sqrt(max(1e-9, variance))
        let z = values.map { ($0 - mean) / max(std, 1e-6) }

        var lastPeakT = times.first ?? 0
        var peaks: [Double] = []
        for i in 1..<(z.count - 1) {
            if z[i] > 0.8 && z[i] > z[i-1] && z[i] > z[i+1] {
                let t = times[i]
                if t - lastPeakT > 0.30 { peaks.append(t); lastPeakT = t }
            }
        }
        guard peaks.count >= 2 else { return 0 }
        let intervals = zip(peaks.dropFirst(), peaks).map { $0 - $1 }
        let medianISI = intervals.sorted()[intervals.count/2]
        return 60.0 / max(medianISI, 1e-6)
    }
}
