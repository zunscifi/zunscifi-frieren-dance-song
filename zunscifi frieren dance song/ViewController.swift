import UIKit
import AVFoundation
import MobileCoreServices

class ViewController: UIViewController, UIDocumentPickerDelegate {
    
    @IBOutlet weak var BUTTON: UIButton!
    @IBOutlet weak var MENU: UIBarButtonItem!
    @IBOutlet weak var PICK_SONG: UILabel!
    
    @IBOutlet weak var VIEW: UIView!
    // Các nút điều khiển trình phát nhạc
    @IBOutlet weak var PLAY_BUTTON: UIImageView!
    @IBOutlet weak var STOP_BUTTON: UIImageView!
    var PROCESS: UISlider!
    
    @IBOutlet weak var containerView: UIView!
    var audioPlayer: AVAudioPlayer?
    var timer: Timer?
    var waveLayers: [CAShapeLayer] = []
    var waveContainerView: UIView!
    
    var isPlaying: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Khởi tạo view chứa sóng nhạc
        setupWaveContainerView()
        
        // Bắt đầu xoay nút BUTTON
        rotateButtonContinuously()
        
        VIEW.layer.cornerRadius = 10;
        VIEW.layer.masksToBounds = true;
        // Thêm sự kiện nhấn giữ và thả cho BUTTON
        BUTTON.addTarget(self, action: #selector(buttonPressed), for: .touchDown)
        BUTTON.addTarget(self, action: #selector(buttonReleased), for: [.touchUpInside, .touchUpOutside])
        
        // Thêm sự kiện cho nhãn PICK_SONG
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pickSong))
        PICK_SONG.isUserInteractionEnabled = true
        PICK_SONG.addGestureRecognizer(tapGesture)
        
        // Khởi tạo hiệu ứng sóng nhạc
        setupWaveLayers()
        
        // Gán sự kiện cho nút Play và Stop
        let playTapGesture = UITapGestureRecognizer(target: self, action: #selector(togglePlayPause))
        PLAY_BUTTON.isUserInteractionEnabled = true
        PLAY_BUTTON.addGestureRecognizer(playTapGesture)
        
        let stopTapGesture = UITapGestureRecognizer(target: self, action: #selector(stopMusic))
        STOP_BUTTON.isUserInteractionEnabled = true
        STOP_BUTTON.addGestureRecognizer(stopTapGesture)
        
        
    }
    
    // Khởi tạo view chứa sóng nhạc
    func setupWaveContainerView() {
        waveContainerView = UIView(frame: self.view.bounds)
        waveContainerView.backgroundColor = .clear
        self.view.insertSubview(waveContainerView, belowSubview: BUTTON) // Thêm dưới BUTTON
    }
    
    // Khởi tạo các layer cho sóng nhạc
    func setupWaveLayers() {
        let colors: [UIColor] = [.red, .orange, .yellow, .green, .blue, .purple, .cyan]
        
        for i in 0..<colors.count {
            let waveLayer = CAShapeLayer()
            waveLayer.fillColor = colors[i].cgColor
            waveContainerView.layer.addSublayer(waveLayer) // Thêm vào waveContainerView
            waveLayers.append(waveLayer)
        }
    }
    
    // Chuyển đổi giữa play và pause
    @objc func togglePlayPause() {
        if isPlaying {
            pauseMusic()
        } else {
            if audioPlayer?.isPlaying == false {
                playMusic()
            }
        }
    }
    
    // Phát nhạc
    @objc func playMusic() {
        audioPlayer?.play()
        PLAY_BUTTON.image = UIImage(systemName: "pause.fill") // Cập nhật icon thành pause
        isPlaying = true
    }
    
    // Tạm dừng nhạc
    @objc func pauseMusic() {
        audioPlayer?.pause()
        PLAY_BUTTON.image = UIImage(systemName: "play.fill") // Cập nhật icon thành play
        isPlaying = false
    }
    
    // Dừng nhạc
    @objc func stopMusic() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0 // Đặt thời gian về đầu
        PICK_SONG.text = "Stopped"
        PLAY_BUTTON.image = UIImage(systemName: "play.fill") // Đặt icon về play
        isPlaying = false
    }
    
    // Cập nhật hình dạng sóng nhạc dựa trên cường độ âm thanh
    func updateWaveLayers(averagePower: Float) {
        let normalizedPower = max(0.0, min(1.0, (averagePower + 160) / 160))
        
        for (index, layer) in waveLayers.enumerated() {
            let waveHeight = CGFloat(normalizedPower) * CGFloat(100 + index * 30) // Thay đổi chiều cao sóng
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: view.bounds.height))
            path.addLine(to: CGPoint(x: view.bounds.width, y: view.bounds.height - waveHeight))
            layer.path = path.cgPath
            
            // Cập nhật vị trí theo cường độ
            layer.position = CGPoint(x: 0, y: CGFloat(index * 30))
        }
    }
    
    // Hàm để xoay BUTTON liên tục
    func rotateButtonContinuously() {
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = 0
        rotation.toValue = 2 * Double.pi
        rotation.duration = 5
        rotation.repeatCount = Float.infinity
        
        BUTTON.layer.add(rotation, forKey: "rotate")
    }
    
    // Khi nhấn giữ nút, thu nhỏ nút lại nhưng vẫn giữ trạng thái xoay
    @objc func buttonPressed() {
        UIView.animate(withDuration: 0.2) {
            self.BUTTON.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }
    }
    
    // Khi thả nút, trả lại kích thước ban đầu nhưng vẫn giữ trạng thái xoay
    @objc func buttonReleased() {
        UIView.animate(withDuration: 0.2) {
            self.BUTTON.transform = CGAffineTransform.identity
        }
    }
    
    // Hàm để chọn file âm thanh
    @objc func pickSong() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.audio])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
    }
    
    // Xử lý khi người dùng chọn file
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first {
            playAudio(from: url)
        }
    }
    
    // Phát âm thanh từ URL
    func playAudio(from url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.isMeteringEnabled = true // Bật chế độ đo đạc âm thanh
            audioPlayer?.play()
            PICK_SONG.text = "Playing: \(url.lastPathComponent)"
            PLAY_BUTTON.image = UIImage(systemName: "pause.fill")
            isPlaying = true
            // Cập nhật UI theo nhịp điệu âm thanh
            startAudioMetering()
        } catch {
            print("Unable to play audio: \(error.localizedDescription)")
        }
    }
    
    // Bắt đầu cập nhật giao diện theo nhịp điệu âm thanh
    func startAudioMetering() {
        // Dừng timer trước nếu đã có
        timer?.invalidate()
        
        // Cập nhật mỗi 0.05 giây
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.audioPlayer?.updateMeters()
            if let averagePower = self?.audioPlayer?.averagePower(forChannel: 0) {
                self?.updateButtonFreeJitter(averagePower: averagePower)
                self?.updateWaveLayers(averagePower: averagePower) // Cập nhật sóng nhạc
            }
        }
    }
    
    func updateButtonFreeJitter(averagePower: Float) {
        let normalizedPower = max(0.0, min(1.0, (averagePower + 160) / 160))
        
        // Nếu cường độ là 0, quay về vị trí mặc định
        if normalizedPower == 0 {
            UIView.animate(withDuration: 0.2) {
                self.BUTTON.center = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
                self.BUTTON.transform = CGAffineTransform.identity // Reset kích thước
            }
            return
        }
        
        let minDuration: TimeInterval = 0.05
        let maxDuration: TimeInterval = 0.3
        let durationFactor = 1.0 - normalizedPower
        let durationDifference = maxDuration - minDuration
        let duration = minDuration + (Double(durationFactor) * durationDifference)
        
        let screenBounds = UIScreen.main.bounds
        let randomX = CGFloat.random(in: 0...(screenBounds.width - BUTTON.frame.width))
        let randomY = CGFloat.random(in: 0...(screenBounds.height - BUTTON.frame.height))
        
        UIView.animate(withDuration: duration, animations: {
            self.BUTTON.center = CGPoint(x: randomX, y: randomY)
        })
    }
    
    // Xử lý khi người dùng hủy chọn file
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("User canceled picking a song.")
    }
    
    // Xử lý khi thanh tiến độ được kéo
    @objc func progressChanged() {
        guard let player = audioPlayer else { return }
        let totalDuration = player.duration
        let newTime = totalDuration * Double(PROCESS.value)
        player.currentTime = newTime
    }
}
