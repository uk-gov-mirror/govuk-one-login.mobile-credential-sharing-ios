import AVFoundation
import CoreBluetooth
import Foundation
import SharingBluetoothTransport
import SharingCameraService
@testable import SharingPrerequisiteGate
import Testing

@MainActor
@Suite("Prerequisite Gate Tests")
struct PrerequisiteGateTests {
    var sut = PrerequisiteGate()
    
    @Test("evaluatePrerequisites returns correct MissingPrerequisite for each CBManagerState")
    func evaluatePrerequisitesReturnCorrectState() throws {
        let mockBlePeripheralTransport = MockBlePeripheralTransport()
        sut.blePeripheralTransport = mockBlePeripheralTransport
        let prerequisite: [Prerequisite] = [.bluetooth]
        
        for state in [CBManagerState.poweredOn, .poweredOff, .resetting, .unknown, .unauthorized, .unsupported] {
            mockBlePeripheralTransport.mockPeripheralManagerState = state
            
            let result = sut.evaluatePrerequisites(for: prerequisite) {}
            
            switch state {
            case .poweredOn:
                #expect(result == [])
            case .unknown:
                #expect(result == [MissingPrerequisite.bluetooth(.stateUnknown)])
            case .resetting:
                #expect(result == [MissingPrerequisite.bluetooth(.stateResetting)])
            case .unsupported:
                #expect(result == [MissingPrerequisite.bluetooth(.stateUnsupported)])
            case .unauthorized:
                #expect(result == [MissingPrerequisite.bluetooth(.stateUnauthorized)])
            case .poweredOff:
                #expect(result == [MissingPrerequisite.bluetooth(.statePoweredOff)])
            @unknown default:
                fatalError("Should never be reached as all cases are covered")
            }
        }
    }
    
    @Test("evaluatePrerequisites returns correct MissingPrerequisite for each CBManagerAuthorization")
    mutating func evaluatePrerequisitesReturnCorrectAuth() throws {
        let mockBlePeripheralTransport = MockBlePeripheralTransport(mockPeripheralManagerState: .poweredOn)
        let prerequisite: [Prerequisite] = [.bluetooth]
        
        for auth in [CBManagerAuthorization.allowedAlways, .notDetermined, .denied, .restricted] {
            sut = PrerequisiteGate(cbManagerAuthorization: auth)
            sut.blePeripheralTransport = mockBlePeripheralTransport
            
            let result = sut.evaluatePrerequisites(for: prerequisite) {}
            
            switch auth {
            case .notDetermined:
                    #expect(result == [MissingPrerequisite.bluetooth(.authorizationNotDetermined)])
            case .restricted:
                    #expect(result == [MissingPrerequisite.bluetooth(.authorizationRestricted)])
            case .denied:
                    #expect(result == [MissingPrerequisite.bluetooth(.authorizationDenied)])
            case .allowedAlways:
                #expect(result == [])
            @unknown default:
                fatalError("Should never be reached as all cases are covered")
            }
        }
    }
    
    @Test("triggerResolution(.bluetooth(.statePoweredOff)) does not show a system prompt and keeps the existing transport")
    mutating func poweredOffResolutionDoesNotShowSystemPrompt() throws {
        // Given: Bluetooth is powered off and a transport already exists from
        // evaluation. The user turns Bluetooth on manually (guided by the
        // on-screen instructions) rather than via a system prompt.
        sut = PrerequisiteGate(cbManagerAuthorization: .allowedAlways)
        let mockBlePeripheralTransport = MockBlePeripheralTransport()
        sut.blePeripheralTransport = mockBlePeripheralTransport

        // When
        sut.triggerResolution(for: MissingPrerequisite.bluetooth(.statePoweredOff))

        // Then: the existing transport is untouched (no new CBPeripheralManager
        // created to trigger a system alert).
        #expect(sut.blePeripheralTransport === mockBlePeripheralTransport)
    }
    
    @Test("evaluatePrerequisites initialises a BlePeripheralTransport if one does not exist")
    func initsPeripheralSession() {
        // Given
        #expect(sut.blePeripheralTransport == nil)

        // When
        _ = sut.evaluatePrerequisites(completion: {})
        
        // Then
        #expect(sut.blePeripheralTransport != nil)
    }
    
    @Test("triggerResolution(for: MissingPrerequisite.bluetooth(.authorizationNotDetermined)) initiates a BlePeripheralTransport")
    func triggerResolutionInitiatesCorrectly() {
        // Given
        #expect(sut.blePeripheralTransport == nil)
        
        // When
        sut.triggerResolution(for: MissingPrerequisite.bluetooth(.authorizationNotDetermined))
        
        // Then
        #expect(sut.blePeripheralTransport != nil)
    }
    
    @Test("triggerResolution(for: MissingPrerequisite.bluetooth(.authorizationNotDetermined)) assigns self as BlePeripheralTransport delegate")
    func triggerResolutionAssignsDelegate() {
        // Given
        #expect(sut.blePeripheralTransport?.delegate == nil)
        
        // When
        sut.triggerResolution(for: MissingPrerequisite.bluetooth(.authorizationNotDetermined))
        
        // Then
        #expect(sut.blePeripheralTransport?.delegate === sut.self)
    }
    

    @Test("bluetoothTransportDidPowerOn calls completion")
    func bluetoothTransportDidPowerOnCallsCompletion() async throws {
        // Given
        var completionCalled = false
        let pendingBluetoothCompletion = {
            completionCalled = true
        }
        
        #expect(completionCalled == false)
        _ = sut.evaluatePrerequisites(completion: pendingBluetoothCompletion)
        
        // When
        sut.bluetoothTransportDidPowerOn()
        
        // Then
        #expect(completionCalled == true)
    }
    
    @Test("bluetoothTransportDidFail calls completion")
    func bluetoothTransportDidFailCallsCompletion() async throws {
        // Given
        var completionCalled = false
        let pendingBluetoothCompletion = {
            completionCalled = true
        }
        
        #expect(completionCalled == false)
        _ = sut.evaluatePrerequisites(completion: pendingBluetoothCompletion)
        
        // When
        sut.bluetoothTransportDidFail(with: .peripheral(.unknown))
        
        // Then
        #expect(completionCalled == true)
    }
    
    @Test("bluetoothTransportDidStartAdvertising does not call completion")
    func didStartAdvertisingDoesNotCallCompletion() {
        // Given
        var completionCalled = false
        let pendingBluetoothCompletion = {
            completionCalled = true
        }
        
        #expect(completionCalled == false)
        _ = sut.evaluatePrerequisites(for: [.bluetooth], completion: pendingBluetoothCompletion)
        
        // When
        sut.bluetoothTransportDidStartAdvertising()
        
        // Then
        #expect(completionCalled == false)
    }
    
    @Test("bluetoothTransportConnectionDidConnect does not call completion")
    func didConnectCentralDoesNotCallCompletion() {
        // Given
        var completionCalled = false
        let pendingBluetoothCompletion = {
            completionCalled = true
        }
        
        #expect(completionCalled == false)
        _ = sut.evaluatePrerequisites(for: [.bluetooth], completion: pendingBluetoothCompletion)
        
        // When
        sut.bluetoothTransportConnectionDidConnect()
        
        // Then
        #expect(completionCalled == false)
    }
    
    @Test("bluetoothTransportDidReceiveMessageData does not call completion")
    func didReceiveMessageDataDoesNotCallCompletion() {
        // Given
        var completionCalled = false
        let pendingBluetoothCompletion = {
            completionCalled = true
        }
        
        #expect(completionCalled == false)
        _ = sut.evaluatePrerequisites(for: [.bluetooth], completion: pendingBluetoothCompletion)
        
        // When
        sut.bluetoothTransportDidReceiveMessageData(Data())
        
        // Then
        #expect(completionCalled == false)
    }
    
    @Test("bluetoothTransportDidReceiveMessageEndRequest does not call completion")
    func didReceiveMessageEndRequestDoesNotCallCompletion() {
        // Given
        var completionCalled = false
        let pendingBluetoothCompletion = {
            completionCalled = true
        }
        
        #expect(completionCalled == false)
        _ = sut.evaluatePrerequisites(for: [.bluetooth], completion: pendingBluetoothCompletion)
        
        // When
        sut.bluetoothTransportDidReceiveMessageEndRequest()
        
        // Then
        #expect(completionCalled == false)
    }
    
    // MARK: - Camera Evaluation Tests
    
    @Test("Unsupported camera hardware returns an unrecoverable missing prerequisite")
    func noCameraHardwareReturnsUnrecoverable() {
        // Given
        let mockCamera = MockCameraCapabilityProvider(isCameraAvailable: false)
        let sut = PrerequisiteGate(
            cbManagerAuthorization: .allowedAlways,
            cameraHardware: mockCamera
        )
        
        // When
        let result = sut.evaluatePrerequisites(for: [.camera]) {}
        
        // Then
        #expect(result == [.camera(.stateUnsupported)])
        #expect(result.first?.isRecoverable == false)
    }
    
    @Test("Camera authorisation not determined returns a recoverable missing prerequisite")
    func cameraNotDeterminedReturnsRecoverable() {
        // Given
        let mockCamera = MockCameraCapabilityProvider(isCameraAvailable: true, authorizationStatus: .notDetermined)
        let sut = PrerequisiteGate(
            cbManagerAuthorization: .allowedAlways,
            cameraHardware: mockCamera
        )
        
        // When
        let result = sut.evaluatePrerequisites(for: [.camera]) {}
        
        // Then
        #expect(result == [.camera(.authorizationNotDetermined)])
        #expect(result.first?.isRecoverable == true)
    }
    
    @Test("Camera authorisation denied returns an unrecoverable missing prerequisite")
    func cameraDeniedReturnsUnrecoverable() {
        // Given
        let mockCamera = MockCameraCapabilityProvider(isCameraAvailable: true, authorizationStatus: .denied)
        let sut = PrerequisiteGate(
            cbManagerAuthorization: .allowedAlways,
            cameraHardware: mockCamera
        )
        
        // When
        let result = sut.evaluatePrerequisites(for: [.camera]) {}
        
        // Then
        #expect(result == [.camera(.authorizationDenied)])
        #expect(result.first?.isRecoverable == false)
    }
    
    @Test("Camera authorisation restricted returns an unrecoverable missing prerequisite")
    func cameraRestrictedReturnsUnrecoverable() {
        // Given
        let mockCamera = MockCameraCapabilityProvider(isCameraAvailable: true, authorizationStatus: .restricted)
        let sut = PrerequisiteGate(
            cbManagerAuthorization: .allowedAlways,
            cameraHardware: mockCamera
        )
        
        // When
        let result = sut.evaluatePrerequisites(for: [.camera]) {}
        
        // Then
        #expect(result == [.camera(.authorizationRestricted)])
        #expect(result.first?.isRecoverable == false)
    }
    
    @Test("Camera authorisation granted returns no missing prerequisite")
    func cameraAuthorizedReturnsNoMissingPrerequisite() {
        // Given
        let mockCamera = MockCameraCapabilityProvider(isCameraAvailable: true, authorizationStatus: .authorized)
        let sut = PrerequisiteGate(
            cbManagerAuthorization: .allowedAlways,
            cameraHardware: mockCamera
        )
        
        // When
        let result = sut.evaluatePrerequisites(for: [.camera]) {}
        
        // Then
        #expect(result.isEmpty)
    }
    
    @Test("triggerResolution for camera authorizationNotDetermined requests access and calls completion")
        func triggerResolutionForCameraRequestsAccessAndCallsCompletion() async {
            // Given
            let mockCamera = MockCameraCapabilityProvider(isCameraAvailable: true, authorizationStatus: .notDetermined)
            let sut = PrerequisiteGate(
                cbManagerAuthorization: .allowedAlways,
                cameraHardware: mockCamera
            )

            // When
            await withCheckedContinuation { continuation in
                _ = sut.evaluatePrerequisites(for: [.camera]) {
                    continuation.resume()
                }
                sut.triggerResolution(for: .camera(.authorizationNotDetermined))
            }

            // Then
            #expect(mockCamera.requestAccessCalled == true)
        }
}
