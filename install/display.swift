// Turns off True Tone and automatic brightness (System Settings > Displays). Neither has a
// defaults key, so this calls the private frameworks that System Settings uses.
import CoreGraphics
import Foundation

func fail(_ message: String) -> Never {
  fputs(message + "\n", stderr)
  exit(1)
}

func load(_ framework: String) -> UnsafeMutableRawPointer? {
  dlopen("/System/Library/PrivateFrameworks/\(framework).framework/\(framework)", RTLD_NOW)
}

let displayServices = load("DisplayServices")
guard let hasSensor = dlsym(displayServices, "DisplayServicesHasAmbientLightCompensation"),
  let enableSensor = dlsym(displayServices, "DisplayServicesEnableAmbientLightCompensation")
else { fail("DisplayServices functions not found") }
let hasAutoBrightness = unsafeBitCast(hasSensor, to: (@convention(c) (CGDirectDisplayID) -> Bool).self)
let setAutoBrightness = unsafeBitCast(enableSensor, to: (@convention(c) (CGDirectDisplayID, Bool) -> Int32).self)

var displays = [CGDirectDisplayID](repeating: 0, count: 16)
var count: UInt32 = 0
CGGetOnlineDisplayList(16, &displays, &count)
for display in displays.prefix(Int(count)) where hasAutoBrightness(display) {
  if setAutoBrightness(display, false) != 0 { fail("Could not turn off automatic brightness") }
}

_ = load("CoreBrightness")
guard let trueToneClass = NSClassFromString("CBTrueToneClient") as? NSObject.Type else {
  fail("CBTrueToneClient not found")
}
let trueTone = trueToneClass.init()
let setEnabled = NSSelectorFromString("setEnabled:")
let setTrueTone = unsafeBitCast(trueTone.method(for: setEnabled), to: (@convention(c) (AnyObject, Selector, Bool) -> Bool).self)
if !setTrueTone(trueTone, setEnabled, false) { fail("Could not turn off True Tone") }
