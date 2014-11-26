package prova.xtend

import com.jogamp.newt.event.KeyEvent
import com.jogamp.newt.event.KeyListener
import com.jogamp.newt.event.WindowAdapter
import com.jogamp.newt.event.WindowEvent
import org.eclipse.xtend.lib.annotations.Accessors

/**
 * Reacts to events that should close the rendering window. 
 */
class QuitAdapter extends WindowAdapter implements KeyListener
{
    @Accessors
    boolean shouldQuit

    override windowDestroyed(WindowEvent we) {
        shouldQuit = true
    }

    override keyPressed(KeyEvent ke) {
    }

    override keyReleased(KeyEvent ke) {
        if ( !ke.printableKey || ke.autoRepeat ) {
            return
        }
        if ( ke.keySymbol == KeyEvent::VK_Q ) {
            shouldQuit = true
        }
    }
}
