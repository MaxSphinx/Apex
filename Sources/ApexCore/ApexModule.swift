import Foundation
import SwiftUI
import Combine

@MainActor
public protocol ApexModule: AnyObject, ObservableObject, Identifiable {
    var id: String { get }
    var name: String { get }
    var description: String { get }
    var iconName: String { get }
    var isEnabled: Bool { get set }
    
    func start()
    func stop()
}

public extension ApexModule {
    var id: String { name }
}
