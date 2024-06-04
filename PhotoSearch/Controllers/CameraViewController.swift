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

        let imageSize = CGSize(width: CVPixelBufferGetWidth(imageBuffer), height: CVPixelBufferGetHeight(imageBuffer))
        let viewPort = sceneView.bounds
        let viewPortSize = sceneView.bounds.size

        let interfaceOrientation : UIInterfaceOrientation
        if #available(iOS 13.0, *) {
            interfaceOrientation = self.sceneView.window!.windowScene!.interfaceOrientation
        } else {
            interfaceOrientation = UIApplication.shared.statusBarOrientation
        }

        let image = CIImage(cvImageBuffer: imageBuffer)

        // The camera image doesn't match the view rotation and aspect ratio
        // Transform the image:

        // 1) Convert to "normalized image coordinates"
        let normalizeTransform = CGAffineTransform(scaleX: 1.0/imageSize.width, y: 1.0/imageSize.height)

        // 2) Flip the Y axis (for some mysterious reason this is only necessary in portrait mode)
        let flipTransform = (interfaceOrientation.isPortrait) ? CGAffineTransform(scaleX: -1, y: -1).translatedBy(x: -1, y: -1) : .identity

        // 3) Apply the transformation provided by ARFrame
        // This transformation converts:
        // - From Normalized image coordinates (Normalized image coordinates range from (0,0) in the upper left corner of the image to (1,1) in the lower right corner)
        // - To view coordinates ("a coordinate space appropriate for rendering the camera image onscreen")
        // See also: https://developer.apple.com/documentation/arkit/arframe/2923543-displaytransform

        let displayTransform = frame.displayTransform(for: interfaceOrientation, viewportSize: viewPortSize)

        // 4) Convert to view size
        let toViewPortTransform = CGAffineTransform(scaleX: viewPortSize.width, y: viewPortSize.height)
        
        guard let rectPoints = rectPoints else {
          // Handle the case where rectPoints is nil
          print("Error: rectPoints not provided for cropping")
          return
        }

        // Assuming you have access to the topLeft, topRight, etc. points

        let rect = CGRect(
            origin: rectPoints.topLeft,
          size: CGSize(
            width: rectPoints.topRight.x - rectPoints.topLeft.x,
            height: rectPoints.bottomRight.y - rectPoints.topLeft.y
          )
        )


        // Transform the image and crop it to the viewport
        let transformedImage = image.transformed(by: normalizeTransform.concatenating(flipTransform).concatenating(displayTransform).concatenating(toViewPortTransform)).cropped(to: rect)
        
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
