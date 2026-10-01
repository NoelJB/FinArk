import heapq
import time
import threading

from collections import namedtuple


Activity = namedtuple("Activity", ["when", "counter", "repeat", "task_name", "callback", "args", "kwargs"])
Repeat = namedtuple("Repeat", ["delay", "count"])


class TimerManager(threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self)
        self.heap = []
        self.ready = threading.Condition()
        self.counter = 0
        self.running = False


    def add_delayed(self, delay, callback, *args, repeat = None, task_name = None, **kwargs):
        if self.running:
            with self.ready:
                when = time.time() + delay
                self.add_timed(when, callback, *args, repeat = repeat, task_name = task_name, **kwargs)


    def add_timed(self, when, callback, *args, repeat = None, task_name = None, **kwargs):
        if self.running:
            with self.ready:
                # counter prevents comparison issues if target times match
                heapq.heappush(self.heap, Activity(when, self.counter, Repeat(*repeat) if type(repeat) in (tuple, list) else repeat, task_name, callback, args, kwargs))
                self.counter += 1
                self.ready.notify()


    def cancel(self, task_name, multiple=False):
        with self.ready:
            if multiple:
                self.heap = [act for act in self.heap if act.task_name != task_name]
                heapq.heapify(self.heap)
            else:
                for i, act in enumerate(self.heap):
                    if act.task_name == task_name:
                        self.heap.pop(i)  # Directly remove the item by index
                        heapq.heapify(self.heap)  # Rebuild the remaining small heap
                        break
            
            self.ready.notify()


    def stop(self):
        if self.running:
            with self.ready:
                self.running = False
                self.heap.clear()
                self.ready.notify() 
        

    @property
    def running(self):
        return self._running


    @running.setter
    def running(self, value: bool):
        self._running = value


    def show_tasks(self):
        with self.ready:
            if self.heap:
                print(f"{'Name':<45s}{'When':<15s}{'Function':<45s}")
                for when, *_, task_name, callback, args, kwargs in self.heap:
                    arglist = ""
                    if args: arglist += ", ".join(str(arg) for arg in args)
                    if kwargs:
                        if arglist: arglist += ", "
                        arglist += ", ".join(f"{k} = {v}" for k,v in kwargs.items())
                    print(f"{task_name if task_name else '':<45s}{when - time.time():<15f}{callback.__name__ + '(' + arglist + ')':<45s}")
            else:
                print("No Tasks Scheduled")
    

    def run(self):
        self.running = True
        
        while True:
            with self.ready:
                if not self.heap:
                    if not self.running:
                        break
                    else:
                        self.ready.wait()
                else:
                    while self.heap and self.heap[0].when <= (now := time.time()):
                        *timing, repeat, task_name, cb, args, kwargs = heapq.heappop(self.heap)
                        try:
                            cb(*args, **kwargs) if args or kwargs else cb()
                        except Exception as e:
                            print(f"Error in Activity { task_name if task_name else cb.__name__} - {type(e)}: {e}")

                        if repeat:
                            # 1. If repeat is a callable, execute it fresh to get the next Repeat instruction
                            next_repeat = repeat() if callable(repeat) else repeat
                            
                            # 2. Check bounds and re-queue using standard or dynamically returned values
                            if next_repeat and next_repeat.count:
                                # If it was a legacy static tuple, pass down the decremented count
                                decremented_repeat = next_repeat if callable(repeat) else Repeat(next_repeat.delay, next_repeat.count - 1)

                                # Keep the original callable reference alive so it executes again on the next tick
                                self.add_delayed(next_repeat.delay, cb, *args, repeat = repeat if callable(repeat) else decremented_repeat, task_name = task_name, **kwargs)
                    else:
                        # Clamped to 0.0 to prevent undocumented or platform-specific negative timeout behavior
                        if self.heap: self.ready.wait(max(0.0, self.heap[0].when - now))


if __name__ == "__main__":
    timed_activities = TimerManager()
    timed_activities.start()
    timed_activities.add_delayed(7, lambda: print("Acted after 7 seconds"))
    timed_activities.add_delayed(3, lambda: print("Acted after 3 seconds"))
    timed_activities.add_delayed(2, lambda: print("Acted after 2 seconds"))
    timed_activities.add_delayed(1, lambda: print("Acted after 1 second"))
    timed_activities.show_tasks()
    time.sleep(4)
    timed_activities.add_timed(time.time() + 2, lambda x : print(f"Acted after {x} seconds"), 6)
    timed_activities.add_timed(time.time() + 1, lambda x : print(f"Acted after {x} seconds"), 5)
    timed_activities.add_delayed(1, lambda x : print(f"Repeating Activity {x}"), 42, repeat = Repeat(1, 10))
    timed_activities.add_delayed(1, lambda x,*,y : print(f"Repeating Activity {x} with {y}"), 42, repeat = Repeat(1, 10), y="Hello World")
    timed_activities.show_tasks()
    time.sleep(5)
    timed_activities.running = False
    print("Requested stop, but it should run to completion", flush=True)
    timed_activities.show_tasks()
    timed_activities.join()
    timed_activities.show_tasks()
