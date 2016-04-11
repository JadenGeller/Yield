import Dispatch

private let coroutineQueue = dispatch_queue_create("coroutine", DISPATCH_QUEUE_CONCURRENT)

public class Coroutine<Element>: GeneratorType {	
	private let callerReady = dispatch_semaphore_create(0)
	private let coroutineReady = dispatch_semaphore_create(0)
	private var done: Bool = false
	private var transportStorage: Element?
	
	public typealias Yield = Element -> ()
	public init(implementation: Yield -> ()) {
		dispatch_async(coroutineQueue) {			
			// Don't start coroutine until first call.
			dispatch_semaphore_wait(self.callerReady, DISPATCH_TIME_FOREVER)
			
			implementation { next in
				// Place element in transport storage, and let caller know it's ready.
				self.transportStorage = next
				dispatch_semaphore_signal(self.coroutineReady)

				// Don't continue coroutine until next call.
				dispatch_semaphore_wait(self.callerReady, DISPATCH_TIME_FOREVER)
			}
			
			// The coroutine is forever over, so let's let the caller know.
			self.done = true
			dispatch_semaphore_signal(self.coroutineReady)
		}
	}
	
	public func next() -> Element? {
		// Make sure work is happening before we wait.
		guard !done else { return nil }
		
		// Return to the coroutine.
		dispatch_semaphore_signal(callerReady)
								
		// Wait until it has finished, then return and clear the result.
		dispatch_semaphore_wait(coroutineReady, DISPATCH_TIME_FOREVER)
		defer { transportStorage = nil }
		return transportStorage
	}
}
