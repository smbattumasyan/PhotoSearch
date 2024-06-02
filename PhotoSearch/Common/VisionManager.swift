//
//  VisionManager.swift
//  PhotoSearch
//
//  Created by Smbat Tumasyan on 02.06.24.
//

import UIKit
import Vision

class VisionManager {
    static let shared = VisionManager()
    
    /// Updates selectedRectangleObservation with the the rectangle found in the given ARFrame at the given location
    func findRectangle(cvPixelBuffer pixelBuffer: CVPixelBuffer, completion: @escaping (_ request: VNRequest?, _ error: Error?) -> Void) {
        // Perform request on background thread
        DispatchQueue.global(qos: .background).async {
            let request = VNDetectRectanglesRequest(completionHandler: completion)
            request.maximumObservations = 1
            request.minimumConfidence = 0.8
            request.minimumAspectRatio = 0.3
            
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .downMirrored, options: [:])
            do {
                try handler.perform([request])
            } catch let error as NSError {
                print("Failed to perform image request: \(error)")
                return
            }
        }
    }
}
