package prova.xtend

import com.jogamp.newt.opengl.GLWindow
import javax.media.opengl.GLEventListener

/**
 * Template class for an OpenGL demo part of this project.
 */
abstract class GlDemo implements GLEventListener
{
    /**
     * Provides the GLWindow to the demo so that it can register
     * its own event listeners.
     */
    def void setWindow(GLWindow window)
    
    /**
     * Updates the world using the current state and the user's input.
     * 
     * @param drawable the OpenGL Drawable
     * @return true if there was an update
     */
    //def protected boolean update(GLAutoDrawable drawable)
}
