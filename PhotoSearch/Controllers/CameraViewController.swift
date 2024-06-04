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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupSceneView()
        if !isARSupported {
            showAlert(message: "AR is not supported on this device.")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isARSupported {
            configShapeLayer()
            startARSession()
            autoDetectRectangle()

            // Reset AR session
            let configuration = ARWorldTrackingConfiguration()
            sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
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
        shapeLayer = CAShapeLayer()
        shapeLayer.bounds = UIScreen.main.bounds
        shapeLayer.anchorPoint = CGPoint.zero
        sceneView.layer.addSublayer(shapeLayer)
    }
    
    private func autoDetectRectangle() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                if let frame = self.sceneView.session.currentFrame?.capturedImage {
                    self.currentFrame = frame
                    self.visionManager.findRectangle(cvPixelBuffer: frame) { [weak self] (request, error) in
                        self?.handleDetectedRectangles(request: request, error: error)
                    }
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

        // Getting captured image size.
        let imageSize = CGSize(width: CVPixelBufferGetWidth(imageBuffer), height: CVPixelBufferGetHeight(imageBuffer))

        // Calculating maximum multipliers for scene view width and height.
        let maxWidthMultiplier = imageSize.width / sceneView.frame.width
        let maxHeightMultiplier = imageSize.height / sceneView.frame.height

        // Calculating view port scaling factor for maximum possible resolution while keeping scene view aspect ratio.
        let scaleFactor = min(maxWidthMultiplier, maxHeightMultiplier)

        // The scaled view port used for cropping captured CIImage.
        let viewPort = CGRect(origin: .zero, size: CGSize(width: sceneView.frame.width * scaleFactor, height: sceneView.frame.height * scaleFactor))

        let interfaceOrientation = UIApplication.shared.statusBarOrientation

        let ciImage = CIImage(cvImageBuffer: imageBuffer)

        // Getting normalized transform to be applied to ciimage.
        let normalizeTransform = CGAffineTransform(scaleX: 1.0 / imageSize.width, y: 1.0 / imageSize.height)
        
        // Getting flip transform to be applied to ciimage.
        let flipTransform = (interfaceOrientation.isPortrait) ? CGAffineTransform(scaleX: -1, y: -1).translatedBy(x: -1, y: -1) : .identity

        // Getting display transform to be applied to ciimage.
        let displayTransform = frame.displayTransform(for: interfaceOrientation, viewportSize: viewPort.size)

        // Getting view port transform to be applied to ciimage.
        let viewPortTransform = CGAffineTransform(scaleX: viewPort.width, y: viewPort.height)
        
        // Applying above transforms and cropping to scaled view port.
        let transformedImage = ciImage
            .transformed(by: normalizeTransform.concatenating(flipTransform).concatenating(displayTransform).concatenating(viewPortTransform))
            .cropped(to: viewPort)
        
        // Convert the transformed CIImage to UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else { return }
        let capturedImage = UIImage(cgImage: cgImage)

        timer?.invalidate()
        sceneView.session.pause()
        
        // Create a Photo object with dummy data
        let photo = Photo(id: UUID().uuidString, description: nil, altDescription: nil, urls: PhotoURLs(raw: "", full: "", regular: "", small: "", thumb: ""), createdAt: ISO8601DateFormatter().string(from: Date()))
        openPhotoDetailViewController(photo: photo, image: capturedImage)
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
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
}


extension UIImage {
    func imageByApplyingClippingBezierPath(_ path: UIBezierPath) -> UIImage {
        // Mask image using path
        guard let maskedImage = imageByApplyingMaskingBezierPath(path) else { return UIImage() }

        // Crop image to frame of path
        let croppedImage = UIImage(cgImage: maskedImage.cgImage!.cropping(to: path.bounds)!)
        
        return croppedImage
    }
    
    func imageByApplyingMaskingBezierPath(_ path: UIBezierPath) -> UIImage? {
        // Define graphic context (canvas) to paint on
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()!
        context.saveGState()

        // Set the clipping mask
        path.addClip()
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))

        guard let maskedImage = UIGraphicsGetImageFromCurrentImageContext() else { return nil }

        // Restore previous drawing context
        context.restoreGState()
        UIGraphicsEndImageContext()

        return maskedImage
    }
    
    func clip(_ path: UIBezierPath) -> UIImage? {
        let frame = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)

        UIGraphicsBeginImageContextWithOptions(self.size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        path.addClip()
        self.draw(in: frame)

        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        context?.restoreGState()
        UIGraphicsEndImageContext()

        return newImage
    }
}
