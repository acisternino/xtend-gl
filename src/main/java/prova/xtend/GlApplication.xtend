package prova.xtend

import com.jogamp.newt.NewtFactory
import com.jogamp.newt.event.WindowAdapter
import com.jogamp.newt.event.WindowEvent
import com.jogamp.newt.opengl.GLWindow
import com.jogamp.opengl.util.FPSAnimator
import javax.media.opengl.FPSCounter
import javax.media.opengl.GLCapabilities
import javax.media.opengl.GLEventListener
import javax.media.opengl.GLProfile

/**
 * Runs the demo class provided at construction time.
 * Also handles the window system-specific objects.
 */
class GlApplication
{
    val glp  = GLProfile.get( GLProfile.GL3 )
    val caps = new GLCapabilities( glp )

    val GLEventListener demo

    var int width
    var int height

    new(Class<? extends GLEventListener> demoClass, int w, int h)
    {
        width  = w
        height = h

        println( 'GL Profile name: ' + glp.name )
        
        demo = demoClass.newInstance
    }

    /**
     * Runs the demo using NEWT.
     */
    def runNewt(String demoName)
    {
        println( 'runNewt()' )

        val display = NewtFactory.createDisplay( null )
        val screen  = NewtFactory.createScreen( display, 0 )

        val glWindow = GLWindow.create( screen, caps )

        // Animator that call the window's display() method 30 times per second
        val animator = new FPSAnimator( glWindow, 30 )

        glWindow.setTitle( demoName )
        glWindow.setSize( width, height )
        glWindow.setVisible( true )
        glWindow.setUpdateFPSFrames( FPSCounter::DEFAULT_FRAMES_PER_INTERVAL, System.err )

        glWindow.addGLEventListener( demo )

        glWindow.addWindowListener( new WindowAdapter {
            override windowDestroyed(WindowEvent ev) {
                // Use a dedicate thread to run the stop() to ensure that the
                // animator stops before program exits.
                new Thread( [
                    animator.stop()
                    System.exit( 0 )
                ] ).start()
            }
        } )

        animator.start()
    }

}
