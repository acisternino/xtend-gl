package prova.xtend

import com.jogamp.newt.event.KeyEvent
import com.jogamp.newt.event.KeyListener
import com.jogamp.newt.event.WindowAdapter
import com.jogamp.newt.event.WindowEvent
import java.util.concurrent.BlockingQueue
import org.eclipse.xtend.lib.annotations.Accessors

import static java.lang.System.err

/**
 * Reacts to events that should close the rendering window. 
 */
class QuitAdapter extends WindowAdapter implements KeyListener
{
    val static char QUIT_KEY = 'q'      // needed to create a real char instead of a String

    @Accessors
    boolean shouldQuit
    
    val BlockingQueue<Integer> eventQueue
    
    new(BlockingQueue<Integer> eventQueue) {
        this.eventQueue = eventQueue
    }

    override windowDestroyed(WindowEvent we) {
        err.println( '[' + Thread::currentThread + '] QUIT Window' )
        shouldQuit = true
    }

    override keyPressed(KeyEvent ke) {
    }
    
    override keyReleased(KeyEvent ke) {
        if ( !ke.printableKey || ke.autoRepeat ) {
            return
        }
        eventQueue.put( new Integer( ke.keyChar ) )
        if ( ke.keyChar == QUIT_KEY ) {
            err.println( '[' + Thread::currentThread + '] QUIT Key' )
            shouldQuit = true
        }
    }
}
