import Foundation

let resourcesURL = Bundle.main.resourceURL!
let scriptURL = resourcesURL.appendingPathComponent("launcher.sh")

let process = Process()
process.executableURL = URL(fileURLWithPath: "/bin/bash")
process.arguments = [scriptURL.path]
try? process.run()
process.waitUntilExit()
