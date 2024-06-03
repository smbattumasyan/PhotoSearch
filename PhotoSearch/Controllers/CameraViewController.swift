//
//  CameraViewController.swift
//  PhotoSearch
//
//  Created by Smbat Tumasyan on 02.06.24.
//

import UIKit
import ARKit
import SnapKit
import Photos

class CameraViewController: UIViewController, ARSCNViewDelegate {

    //MARK: Outlet Properties
    private var sceneView: ARSCNView!
    
    //MARK: Private Properties
    private var isARSupported = ARConfiguration.isSupported
    private var currentFrame: CVPixelBuffer?
    private var visionManager = VisionManager()
    private var shapeLayer = CAShapeLayer()
    private var timer: Timer?
    private var captureAcceptingCount: Int = 0
    private var rectPoints: (topLeft: CGPoint, topRight: CGPoint, bottomRight: CGPoint, bottomLeft: CGPoint)?
    private var lastPath = UIBezierPath()
    
    //MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSceneView()
        if !isARSupported {
            // Handle the case where AR is not supported
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isARSupported {
            configShapeLayer()
            startARSession()
            autoDetectRectangle()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isARSupported {
            sceneView.session.pause()
        }
    }

    // MARK: - Private Methods
    private func setupSceneView() {
        sceneView = ARSCNView()
        view.addSubview(sceneView)
        sceneView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        if isARSupported {
            sceneView.delegate = self
            sceneView.preferredFramesPerSecond = 30
            let scene = SCNScene()
            sceneView.scene = scene
        }
    }

    private func startARSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration)
    }
    
    private func configShapeLayer() {
        shapeLayer.removeFromSuperlayer()
        shapeLayer.bounds = UIScreen.main.bounds
        shapeLayer.anchorPoint = CGPoint.zero
        sceneView.layer.addSublayer(shapeLayer)
    }
    
    private func autoDetectRectangle() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if let frame = self.sceneView.session.currentFrame?.capturedImage {
                self.currentFrame = frame
                self.visionManager.findRectangle(cvPixelBuffer: frame) { [weak self] (request, error) in
                    self?.handleDetectedRectangles(request: request, error: error)
                }
            }
        }
    }
    
    private func handleDetectedRectangles(request: VNRequest?, error: Error?) {
        if let nsError = error as NSError? {
            print("Rectangle Detection Error \(nsError)")
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let results = request?.results as? [VNRectangleObservation] else { return }
            self.draw(rectangles: results)
            self.shapeLayer.setNeedsDisplay()
            if self.captureAcceptingCount > 1 {
                self.captureAcceptingCount = 0
                self.captureImageFromSceneView()
            }
        }
    }
    
    private func draw(rectangles: [VNRectangleObservation]) {
        if let observation = rectangles.first {
            shapeLayer.removeFromSuperlayer()
            shapeLayerRect(color: .purple, observation: observation)
            sceneView.layer.addSublayer(shapeLayer)
        }
    }
    
    private func shapeLayerRect(color: UIColor, observation: VNRectangleObservation) {
        let linePath = scalePath(observation: observation)
        rectPoints = linePath.0!
        
        if sizesDiffValue(lhs: linePath.1.bounds.size, rhs: lastPath.bounds.size) < 5 {
            captureAcceptingCount += 1
        } else {
            captureAcceptingCount = 0
        }
        drawShapeLayer(color: color, linePath: linePath.1)
        lastPath = linePath.1
    }
    
    private func scalePath(observation: VNRectangleObservation) -> ((CGPoint, CGPoint, CGPoint, CGPoint)?, UIBezierPath) {
        let drawBounds = sceneView.bounds
        let orientation = UIApplication.shared.statusBarOrientation
        guard let arTransform = sceneView.session.currentFrame?.displayTransform(for: orientation, viewportSize: drawBounds.size) else { return (nil, UIBezierPath()) }
        let t = CGAffineTransform(scaleX: drawBounds.width, y: drawBounds.height)
        
        let convertedTopLeft = observation.topLeft.applying(arTransform).applying(t)
        let convertedTopRight = observation.bottomLeft.applying(arTransform).applying(t)
        let convertedBottomLeft = observation.topRight.applying(arTransform).applying(t)
        let convertedBottomRight = observation.bottomRight.applying(arTransform).applying(t)
        
        let linePath = UIBezierPath()
        linePath.move(to: convertedTopLeft)
        linePath.addLine(to: convertedTopRight)
        linePath.addLine(to: convertedBottomRight)
        linePath.addLine(to: convertedBottomLeft)
        linePath.close()
        return ((convertedTopLeft, convertedTopRight, convertedBottomRight, convertedBottomLeft), linePath)
    }
    
    private func drawShapeLayer(color: UIColor, linePath: UIBezierPath ) {
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.lineWidth = 2
        shapeLayer.path = linePath.cgPath
        shapeLayer.fillColor = UIColor.purple.withAlphaComponent(0.5).cgColor
        
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = shapeLayer.path
        animation.toValue = linePath.cgPath
        animation.duration = 0.15
        shapeLayer.add(animation, forKey: nil)
    }
    
    private func captureImageFromSceneView() {
        guard let frame = sceneView.session.currentFrame else { return }
        
        let imageBuffer = frame.capturedImage
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        let image = UIImage(cgImage: cgImage)
        
        guard let rectPoints = rectPoints else { return }
        guard let croppedImage = cropImage(image: image, rectPoints: rectPoints) else {
            print("Failed to crop image")
            return
        }

        timer?.invalidate()
        
        // Create a Photo object with dummy data
        let photo = Photo(id: UUID().uuidString, description: nil, altDescription: nil, urls: PhotoURLs(raw: "", full: "", regular: "", small: "", thumb: ""), createdAt: ISO8601DateFormatter().string(from: Date()))
        openPhotoDetailViewController(photo: photo, image: croppedImage)
    }

    
    private func cropImage(image: UIImage, rectPoints: (topLeft: CGPoint, topRight: CGPoint, bottomRight: CGPoint, bottomLeft: CGPoint)) -> UIImage? {
        guard let ciImage = CIImage(image: image) else {
            print("Failed to create CIImage from UIImage")
            return nil
        }

        guard let perspectiveCorrection = CIFilter(name: "CIPerspectiveCorrection") else {
            print("Failed to create CIFilter")
            return nil
        }

        perspectiveCorrection.setValue(ciImage, forKey: kCIInputImageKey)
        perspectiveCorrection.setValue(CIVector(cgPoint: rectPoints.topLeft), forKey: "inputTopLeft")
        perspectiveCorrection.setValue(CIVector(cgPoint: rectPoints.topRight), forKey: "inputTopRight")
        perspectiveCorrection.setValue(CIVector(cgPoint: rectPoints.bottomRight), forKey: "inputBottomRight")
        perspectiveCorrection.setValue(CIVector(cgPoint: rectPoints.bottomLeft), forKey: "inputBottomLeft")

        guard let outputImage = perspectiveCorrection.outputImage else {
            print("Failed to create output image")
            return nil
        }

        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            print("Failed to create CGImage from output image")
            return nil
        }

        return UIImage(cgImage: cgImage)
    }


    
    private func openPhotoDetailViewController(photo: Photo, image: UIImage) {
        let photoDetailVC = PhotoDetailViewController(photo: photo)
        photoDetailVC.capturedPhoto = image
        navigationController?.pushViewController(photoDetailVC, animated: true)
    }
    
    private func sizesDiffValue(lhs: CGSize, rhs: CGSize) -> Int {
        let w: Int = Int(lhs.width - rhs.width)
        let h: Int = Int(lhs.height - rhs.height)
        return abs(w) + abs(h)
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
}
