import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    var windowFrame = self.frame
    
    // Set a larger initial size (e.g. 800x600)
    windowFrame.size = NSSize(width: 850, height: 650)
    
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    
    // Set a minimum size to prevent the window from being resized too small
    self.minSize = NSSize(width: 600, height: 500)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
