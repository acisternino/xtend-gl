package prova.xtend

import com.jogamp.newt.opengl.GLWindow
import com.jogamp.opengl.util.glsl.ShaderCode
import com.jogamp.opengl.util.glsl.ShaderProgram
import com.jogamp.opengl.util.glsl.ShaderState
import javax.media.opengl.DebugGL3
import javax.media.opengl.GL
import javax.media.opengl.GL2ES2
import javax.media.opengl.GL3
import javax.media.opengl.GLAutoDrawable

import static com.jogamp.common.nio.Buffers.*

/**
 *
 */
class OneCube extends GlDemo
{
    val static SHADERS_DIR     = 'shaders'
    val static SHADERS_BIN_DIR = SHADERS_DIR + '/bin'
    val static SHADERS_BASE_NAME = typeof( OneCube ).simpleName.toLowerCase

    val static int CLEAR_BUFFER_BITS = GL::GL_COLOR_BUFFER_BIT.bitwiseOr( GL::GL_DEPTH_BUFFER_BIT )

    // Array containing buffer and vertex indices (i.e. names).
    // This is kind of a "directory" of buffer objects where their ID's are stored.

    val int[] vbos = newIntArrayOfSize( 1 )     // for Vertex Buffer Objects
    val int[] ibos = newIntArrayOfSize( 1 )     // for Index  Buffer Objects
    val int[] vaos = newIntArrayOfSize( 1 )     // for Vertex Array  Objects

    // These vertices will be used to build a VBO to draw a cube

    val float[] vertices = #[
        0.35f, -0.71f,  0.35f,   1f, 0f, 0f,    //  0 red
        0.85f, -0.00f, -0.15f,   1f, 0f, 0f,    //  1 red
        0.35f,  0.71f,  0.35f,   1f, 0f, 0f,    //  2 red
       -0.15f,  0.00f,  0.85f,   1f, 0f, 0f,    //  3 red

       -0.15f,  0.00f,  0.85f,   0f, 1f, 0f,    //  4 green
        0.35f, -0.71f,  0.35f,   0f, 1f, 0f,    //  5 green
       -0.35f, -0.71f, -0.35f,   0f, 1f, 0f,    //  6 green
       -0.85f,  0.00f,  0.15f,   0f, 1f, 0f,    //  7 green

       -0.85f,  0.00f,  0.15f,   0f, 0f, 1f,    //  8 blue
       -0.35f,  0.71f, -0.35f,   0f, 0f, 1f,    //  9 blue
        0.15f, -0.00f, -0.85f,   0f, 0f, 1f,    // 10 blue
       -0.35f, -0.71f, -0.35f,   0f, 0f, 1f,    // 11 blue

       -0.35f, -0.71f, -0.35f,   1f, 1f, 0f,    // 12 yellow
        0.35f, -0.71f,  0.35f,   1f, 1f, 0f,    // 13 yellow
        0.85f, -0.00f, -0.15f,   1f, 1f, 0f,    // 14 yellow
        0.15f, -0.00f, -0.85f,   1f, 1f, 0f,    // 15 yellow

        0.15f, -0.00f, -0.85f,   1f, 0f, 1f,    // 16 magenta
        0.85f, -0.00f, -0.15f,   1f, 0f, 1f,    // 17 magenta
        0.35f,  0.71f,  0.35f,   1f, 0f, 1f,    // 18 magenta
       -0.35f,  0.71f, -0.35f,   1f, 0f, 1f,    // 19 magenta

       -0.35f,  0.71f, -0.35f,   0f, 1f, 1f,    // 20 cyan
       -0.85f,  0.00f,  0.15f,   0f, 1f, 1f,    // 21 cyan
       -0.15f,  0.00f,  0.85f,   0f, 1f, 1f,    // 22 cyan
        0.35f,  0.71f,  0.35f,   0f, 1f, 1f     // 23 cyan
    ]

    val short[] indices = #[
         0 as short,  1 as short,  2 as short,   // face 1
         2 as short,  3 as short,  0 as short,

         4 as short,  6 as short,  5 as short,   // face 2
         4 as short,  7 as short,  6 as short,

        10 as short,  8 as short,  9 as short,   // face 3
        10 as short, 11 as short,  8 as short,

        12 as short, 15 as short, 13 as short,   // face 4
        15 as short, 14 as short, 13 as short,

        17 as short, 16 as short, 19 as short,   // face 5
        17 as short, 19 as short, 18 as short,

        21 as short, 22 as short, 20 as short,   // face 6
        22 as short, 23 as short, 20 as short
    ]

    // Global OpenGL objects

    val sState = new ShaderState

    // Shader attribute indexes

    var int vertPosLoc
    var int vertColourLoc

    //---- GLEventListener ----------------------------------------------------

    /**
     * Executed only once at startup
     */
    override init(GLAutoDrawable drawable)
    {
        println( 'init' )

        // Activate debug pipeline
        drawable.setGL( new DebugGL3( drawable.GL.getGL3 ) )
    }

    /**
     * Called once at startup (after init()) and every time the window is resized.
     */
    override reshape(GLAutoDrawable drawable, int x, int y, int width, int height)
    {
        println( 'reshape' )

        val gl = drawable.GL.getGL3

        // Clear screen to grey
        gl.glClearColor( 0.4f, 0.4f, 0.4f, 0f )

        // Shaders
        createShaders( gl )

        // VBO
        gl.glGenBuffers( 1, vbos, 0 )
        gl.glBindBuffer( GL::GL_ARRAY_BUFFER, vbos.get( 0 ) )
        gl.glBufferData( GL::GL_ARRAY_BUFFER, vertices.size * SIZEOF_FLOAT, newDirectFloatBuffer( vertices ), GL::GL_STATIC_DRAW )
        gl.glBindBuffer( GL::GL_ARRAY_BUFFER, 0 )

        // Vertex indices
        gl.glGenBuffers( 1, ibos, 0 )
        gl.glBindBuffer( GL::GL_ELEMENT_ARRAY_BUFFER, ibos.get( 0 ) )
        gl.glBufferData( GL::GL_ELEMENT_ARRAY_BUFFER, indices.size * SIZEOF_SHORT, newDirectShortBuffer( indices ), GL::GL_STATIC_DRAW )
        gl.glBindBuffer( GL::GL_ELEMENT_ARRAY_BUFFER, 0 )

        // Create VAO id
        gl.glGenVertexArrays( 1, vaos, 0 )

        // Bind VAO to capture state
        gl.glBindVertexArray( vaos.get( 0 ) )

        // Define structure of VBO
        gl.glBindBuffer( GL::GL_ARRAY_BUFFER, vbos.get( 0 ) )

        val stride = 6 * SIZEOF_FLOAT       // six float attributes per vertex: x,y,z,r,g,b

        gl.glEnableVertexAttribArray( vertPosLoc )
        gl.glVertexAttribPointer( vertPosLoc, 3, GL::GL_FLOAT, false, stride, 0 )

        gl.glEnableVertexAttribArray( vertColourLoc )
        gl.glVertexAttribPointer( vertColourLoc, 3, GL::GL_FLOAT, false, stride, ( 3 * SIZEOF_FLOAT ) )

        // Bind index array to VAO
        gl.glBindBuffer( GL::GL_ELEMENT_ARRAY_BUFFER, ibos.get( 0 ) )

        // Enable face culling
        gl.glEnable( GL::GL_CULL_FACE )
        gl.glCullFace( GL::GL_BACK )
        gl.glFrontFace( GL::GL_CW )

        gl.glBindVertexArray( 0 )
    }

    /**
     * Called once for each frame.
     */
    override display(GLAutoDrawable drawable)
    {
        updateWorld
        render( drawable )
    }

    /**
     *
     */
    override dispose(GLAutoDrawable drawable)
    {
        println( 'dispose' )
    }

    //---- Rendering methods --------------------------------------------------

    def private updateWorld()
    {
        // update world model
    }

    def private render(GLAutoDrawable drawable)
    {
        val gl = drawable.getGL().getGL3()

        // Clear screen
        gl.glClear( CLEAR_BUFFER_BITS )

        // Use shaders
        sState.useProgram( gl, true )

        // Bind VAO
        gl.glBindVertexArray( vaos.get( 0 ) )

        // Draw the cube!
        gl.glDrawElements( GL::GL_TRIANGLES, indices.size, GL::GL_UNSIGNED_SHORT, 0L )      // must be GL_UNSIGNED_SHORT!

        gl.glBindVertexArray( 0 )
        sState.useProgram( gl, false )
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

        // Shader program
        sState.setVerbose( false )

        val sp = new ShaderProgram

        sp.add( gl, vs, System.err )
        sp.add( gl, fs, System.err )

        sState.attachShaderProgram( gl, sp, true )

        // Extract attribute locations
        vertPosLoc    = sState.getAttribLocation( gl, "vert_position" )
        vertColourLoc = sState.getAttribLocation( gl, "vert_colour" )

        sState.useProgram( gl, true )
    }
    
    override setWindow(GLWindow window) {
    }
    
}
