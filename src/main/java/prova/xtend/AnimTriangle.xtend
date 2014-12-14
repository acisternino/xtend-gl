package prova.xtend

import com.jogamp.newt.opengl.GLWindow
import com.jogamp.opengl.util.glsl.ShaderCode
import com.jogamp.opengl.util.glsl.ShaderProgram
import javax.media.opengl.GL
import javax.media.opengl.GL2ES2
import javax.media.opengl.GL3
import javax.media.opengl.GLAutoDrawable
import javax.media.opengl.GLPipelineFactory

import static com.jogamp.common.nio.Buffers.*
import static java.lang.Math.sin

/**
 * Draws an animated triangle in 2D.
 */
class AnimTriangle extends GlDemo
{
    val static SHADERS_DIR       = 'shaders'
    val static SHADERS_BIN_DIR   = SHADERS_DIR + '/bin'
    val static SHADERS_BASE_NAME = AnimTriangle.simpleName.toLowerCase

    val static CLEAR_BUFFER_BITS = GL::GL_COLOR_BUFFER_BIT.bitwiseOr( GL::GL_DEPTH_BUFFER_BIT )

    // Array containing buffer and vertex indices (i.e. names).
    // This is kind of a "directory" of buffer objects where their ID's are stored.

    val vbos = newIntArrayOfSize( 2 )     // for Vertex Buffer Objects
    val vaos = newIntArrayOfSize( 1 )     // for Vertex Array  Objects

    // These points will be used to build a VBO and be used to draw a triangle

    val float[] points = #[
        -0.1f,  -0.3f,
         0.3f,   0.5f,
         0.7f,  -0.3f
    ]

    val float[] colors = #[
        1.0f,  0.0f,  0.0f,
        0.0f,  1.0f,  0.0f,
        0.0f,  0.0f,  1.0f
    ]

    // Global OpenGL objects

    val shProg = new ShaderProgram

    // Shader attributes

    int vertPosLoc          // Location of attribute "vert_position" in vertex shader
    int vertColorLoc        // Location of attribute "vert_color" in vertex shader
    int offsetLoc           // Location of uniform "offset_x" in vertex shader

    // Fields

    float delta             // degrees per frame
    float offset            // linear offset along x axis

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

        //---- Fields -------------------------------------

        delta = ( Math.PI * 2 / 30 ) as float

        //---- Shaders ------------------------------------

        createShaders( gl )
        shProg.useProgram( gl, true )

        //---- Vertex Buffer Objects ----------------------

        // Generate 2 ids ( vertices and colors )
        gl.glGenBuffers( 2, vbos, 0 )

        // VBO with vertex coordinates
        gl.glBindBuffer( GL::GL_ARRAY_BUFFER, vbos.get( 0 ) )
        gl.glBufferData( GL::GL_ARRAY_BUFFER, points.length * SIZEOF_FLOAT, newDirectFloatBuffer( points ), GL::GL_STATIC_DRAW )
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

        gl.glBindVertexArray( 0 )

        //---- General setup ------------------------------

        // Clear screen to grey
        gl.glClearColor( 0.3f, 0.3f, 0.3f, 0f )

        shProg.useProgram( gl, false )
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
        // Update world...
        update( drawable )

        // ...and render it
        render( drawable )
    }

    /**
     * Called once at program termination.
     */
    override dispose(GLAutoDrawable drawable)
    {
        println( 'dispose' )

        val gl = drawable.GL.getGL3

        shProg.release( gl, true )
    }

    //---- Rendering methods --------------------------------------------------

    def private update(GLAutoDrawable drawable)
    {
        val frames = drawable.animator.totalFPSFrames

        offset = ( ( sin( ( frames % 30 ) * delta ) / 2 ) - 0.25 ) as float
    }

    def private render(GLAutoDrawable drawable)
    {
        val gl = drawable.GL.getGL3

        // Clear screen
        gl.glClear( CLEAR_BUFFER_BITS )

        // Use shaders
        shProg.useProgram( gl, true )

        // Bind VAO
        gl.glBindVertexArray( vaos.get( 0 ) )

        // Set uniform
        gl.glUniform1f( offsetLoc, offset )

        // Draw the triangle !
        gl.glDrawArrays( GL::GL_TRIANGLES, 0, 3 )    // from vertex 0, 3 vertices -> 1 triangle

        gl.glBindVertexArray( 0 )

        // Un-use shaders
        shProg.useProgram( gl, false )
    }

    //---- Support methods ----------------------------------------------------

    def private createShaders(GL3 gl)
    {
        // Vertex shader
        val vs = ShaderCode.create( gl, GL2ES2::GL_VERTEX_SHADER, this.class, SHADERS_DIR, SHADERS_BIN_DIR,
            SHADERS_BASE_NAME, true )

        // Fragment shader
        val fs = ShaderCode.create( gl, GL2ES2::GL_FRAGMENT_SHADER, this.class, SHADERS_DIR, SHADERS_BIN_DIR,
            SHADERS_BASE_NAME, true )

        // Create & Link the shader program
        shProg.add( gl, vs, System.err )
        shProg.add( gl, fs, System.err )
        shProg.link( gl, System.err )

        // Extract attribute and uniform locations
        vertPosLoc   = gl.glGetAttribLocation( shProg.program, 'vert_position' )
        vertColorLoc = gl.glGetAttribLocation( shProg.program, 'vert_color' )

        offsetLoc = gl.glGetUniformLocation( shProg.program, 'offset_x' )
    }

    override setWindow(GLWindow window) {
    }

}
