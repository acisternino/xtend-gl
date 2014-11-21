package prova.xtend

import com.jogamp.opengl.util.glsl.ShaderCode
import com.jogamp.opengl.util.glsl.ShaderProgram
import com.jogamp.opengl.util.glsl.ShaderState
import javax.media.opengl.GL
import javax.media.opengl.GL2ES2
import javax.media.opengl.GL3
import javax.media.opengl.GLAutoDrawable
import javax.media.opengl.GLEventListener
import javax.media.opengl.GLPipelineFactory

import static com.jogamp.common.nio.Buffers.*

/**
 *
 */
class ThreeLines implements GLEventListener
{
    val static SHADERS_DIR     = 'shaders'
    val static SHADERS_BIN_DIR = SHADERS_DIR + '/bin'
    val static SHADERS_BASE_NAME = ThreeLines.simpleName.toLowerCase

    val static int CLEAR_BUFFER_BITS = GL::GL_COLOR_BUFFER_BIT.bitwiseOr( GL::GL_DEPTH_BUFFER_BIT )

    // Array containing buffer and vertex indices (i.e. names).
    // This is kind of a "directory" of buffer objects where their ID's are stored.

    val int[] vbos = newIntArrayOfSize( 2 )     // for Vertex Buffer Objects
    val int[] vaos = newIntArrayOfSize( 1 )     // for Vertex Array  Objects

    // These points will be used to build a VBO and draw 3 lines

    val float[] vertices = #[
        // X      Y  
        -0.6f, -0.6f,
         0.0f,  0.6f,
         0.7f,  0.0f,
         0.0f, -0.6f
    ]

    val float[] colors = #[
        0.25f,  0.55f,  0.92f,
        0.46f,  0.66f,  0.15f,
        0.73f,  0.50f,  0.95f,
        0.96f,  0.89f,  0.55f
    ]

    // Global OpenGL objects

    val sState = new ShaderState

    // Shader attributes

    var int vertPosLoc          // Location of attribute "vert_position" in vertex shader
    var int vertColorLoc        // Location of attribute "vert_color" in vertex shader

    //---- GLEventListener ----------------------------------------------------

    /**
     * Called only once at startup.
     */
    override init(GLAutoDrawable drawable)
    {
        println( 'init' )

        // Activate debug pipeline
        var gl = drawable.GL.getGL3
        gl = gl.context.setGL( GLPipelineFactory.create( 'javax.media.opengl.Debug', GL3, gl, null ) ) as GL3

        //---- Shaders ------------------------------------

        createShaders( gl )
        sState.useProgram( gl, true )

        //---- Vertex Buffer Objects ----------------------

        // Generate 2 ids ( vertices and colors )
        gl.glGenBuffers( 2, vbos, 0 )

        // VBO with vertex coordinates
        gl.glBindBuffer( GL::GL_ARRAY_BUFFER, vbos.get( 0 ) )
        gl.glBufferData( GL::GL_ARRAY_BUFFER, vertices.size * SIZEOF_FLOAT, newDirectFloatBuffer( vertices ), GL::GL_STATIC_DRAW )
        gl.glBindBuffer( GL::GL_ARRAY_BUFFER, 0 )

        // VBO with vertex colors
        gl.glBindBuffer( GL::GL_ARRAY_BUFFER, vbos.get( 1 ) )
        gl.glBufferData( GL::GL_ARRAY_BUFFER, colors.size * SIZEOF_FLOAT, newDirectFloatBuffer( colors ), GL::GL_STATIC_DRAW )
        gl.glBindBuffer( GL::GL_ARRAY_BUFFER, 0 )

        //---- Vertex Array Objects -----------------------

        gl.glGenVertexArrays( 1, vaos, 0 )
        gl.glBindVertexArray( vaos.get( 0 ) )

        // Define structure of vertices VBO
        gl.glBindBuffer( GL::GL_ARRAY_BUFFER, vbos.get( 0 ) )
        gl.glEnableVertexAttribArray( vertPosLoc )
        gl.glVertexAttribPointer( vertPosLoc, 2, GL::GL_FLOAT, false, 0, 0 )

        // Define structure of colors VBO
        gl.glBindBuffer( GL::GL_ARRAY_BUFFER, vbos.get( 1 ) )
        gl.glEnableVertexAttribArray( vertColorLoc )
        gl.glVertexAttribPointer( vertColorLoc, 3, GL::GL_FLOAT, false, 0, 0 )

        // Define width of lines
        gl.glLineWidth( 2 )

        // Set Line Antialiasing
        gl.glEnable( GL::GL_LINE_SMOOTH )

        gl.glBindVertexArray( 0 )

        //---- General setup ------------------------------

        // Clear screen to grey
        gl.glClearColor( 0.3f, 0.3f, 0.3f, 0f )

        sState.useProgram( gl, false )
    }

    /**
     * Called once at startup (after init()) and every time the window is resized.
     */
    override reshape(GLAutoDrawable drawable, int x, int y, int width, int height)
    {
        println( 'reshape' )
    }

    /**
     * Called once for each frame.
     */
    override display(GLAutoDrawable drawable)
    {
        val gl = drawable.getGL().getGL3()

        // Use shaders
        sState.useProgram( gl, true )

        // Update world...
        update( drawable )

        // ...and render it
        render( drawable )

        sState.useProgram( gl, false )
    }

    /**
     *
     */
    override dispose(GLAutoDrawable drawable)
    {
        println( 'dispose' )

        val gl = drawable.GL.getGL3

        sState.destroy( gl )
    }

    //---- Support methods ----------------------------------------------------

    def private createShaders(GL3 gl)
    {
        // Vertex shader
        val ShaderCode vs = ShaderCode.create( gl, GL2ES2::GL_VERTEX_SHADER, this.class,
            SHADERS_DIR, SHADERS_BIN_DIR, SHADERS_BASE_NAME, true )

        // Fragment shader
        val ShaderCode fs = ShaderCode.create( gl, GL2ES2::GL_FRAGMENT_SHADER, this.class,
            SHADERS_DIR, SHADERS_BIN_DIR, SHADERS_BASE_NAME, true )

        // Create & Link the shader program
        val sp = new ShaderProgram
        sp.add( gl, vs, System.err )
        sp.add( gl, fs, System.err )

        sState.attachShaderProgram( gl, sp, true )

        // Extract attribute locations
        vertPosLoc   = sState.getAttribLocation( gl, 'vert_position' )
        vertColorLoc = sState.getAttribLocation( gl, 'vert_color' )
    }

    //---- Private methods ----------------------------------------------------

    def private update(GLAutoDrawable drawable)
    {
        // Nothing to do
    }

    def private render(GLAutoDrawable drawable)
    {
        val gl = drawable.GL.getGL3

        // Clear screen
        gl.glClear( CLEAR_BUFFER_BITS )

        // Bind VAO
        gl.glBindVertexArray( vaos.get( 0 ) )

        // Draw the lines!
        gl.glDrawArrays( GL::GL_LINE_STRIP, 0, 4 )      // 4 vertices -> 3 lines

        // Unbind VAO
        gl.glBindVertexArray( 0 )
    }
}
