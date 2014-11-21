package prova.xtend

import com.jogamp.opengl.util.PMVMatrix
import com.jogamp.opengl.util.glsl.ShaderCode
import com.jogamp.opengl.util.glsl.ShaderProgram
import com.jogamp.opengl.util.glsl.ShaderState
import javax.media.opengl.GL
import javax.media.opengl.GL2ES2
import javax.media.opengl.GL3
import javax.media.opengl.GLAutoDrawable
import javax.media.opengl.GLEventListener
import javax.media.opengl.GLPipelineFactory
import javax.media.opengl.GLUniformData

import static com.jogamp.common.nio.Buffers.*
import static javax.media.opengl.fixedfunc.GLMatrixFunc.*

/**
 * Spinning cube.
 */
class SpinCube implements GLEventListener
{
    val static SHADERS_DIR       = 'shaders'
    val static SHADERS_BIN_DIR   = SHADERS_DIR + '/bin'
    val static SHADERS_BASE_NAME = SpinCube.simpleName.toLowerCase

    val static CLEAR_BUFFER_BITS = GL::GL_COLOR_BUFFER_BIT.bitwiseOr( GL::GL_DEPTH_BUFFER_BIT )

    // Array containing buffer and vertex indices (i.e. names).
    // This is kind of a "directory" of buffer objects where their ID's are stored.

    val vbos = newIntArrayOfSize( 1 )       // for Vertex Buffer Objects
    val ibos = newIntArrayOfSize( 1 )       // for Index  Buffer Objects
    val vaos = newIntArrayOfSize( 1 )       // for Vertex Array  Objects

    // These vertices will be used to build a VBO to draw a cube

    val float[] vertices = #[
         1f,  1f,  1f,      1f, 0f, 0f,    //  0 red
         1f,  1f, -1f,      1f, 0f, 0f,    //  1 red
         1f, -1f, -1f,      1f, 0f, 0f,    //  2 red
         1f, -1f,  1f,      1f, 0f, 0f,    //  3 red

         1f, -1f,  1f,      0f, 1f, 0f,    //  4 green
         1f,  1f,  1f,      0f, 1f, 0f,    //  5 green
        -1f,  1f,  1f,      0f, 1f, 0f,    //  6 green
        -1f, -1f,  1f,      0f, 1f, 0f,    //  7 green

        -1f, -1f,  1f,      0f, 0f, 1f,    //  8 blue
        -1f, -1f, -1f,      0f, 0f, 1f,    //  9 blue
        -1f,  1f, -1f,      0f, 0f, 1f,    // 10 blue
        -1f,  1f,  1f,      0f, 0f, 1f,    // 11 blue

        -1f,  1f,  1f,      1f, 1f, 0f,    // 12 yellow
         1f,  1f,  1f,      1f, 1f, 0f,    // 13 yellow
         1f,  1f, -1f,      1f, 1f, 0f,    // 14 yellow
        -1f,  1f, -1f,      1f, 1f, 0f,    // 15 yellow

        -1f,  1f, -1f,      1f, 0f, 1f,    // 16 magenta
         1f,  1f, -1f,      1f, 0f, 1f,    // 17 magenta
         1f, -1f, -1f,      1f, 0f, 1f,    // 18 magenta
        -1f, -1f, -1f,      1f, 0f, 1f,    // 19 magenta

        -1f, -1f, -1f,      0f, 1f, 1f,    // 20 cyan
         1f, -1f, -1f,      0f, 1f, 1f,    // 21 cyan
         1f, -1f,  1f,      0f, 1f, 1f,    // 22 cyan
        -1f, -1f,  1f,      0f, 1f, 1f     // 23 cyan
    ]

    val short[] indices = #[
         0 as short,  1 as short,  2 as short,   // face 1
         2 as short,  3 as short,  0 as short,

         4 as short,  6 as short,  5 as short,   // face 2
         4 as short,  7 as short,  6 as short,

         8 as short,  9 as short, 10 as short,   // face 3
        10 as short, 11 as short,  8 as short,

        12 as short, 15 as short, 13 as short,   // face 4
        15 as short, 14 as short, 13 as short,

        17 as short, 16 as short, 18 as short,   // face 5
        18 as short, 16 as short, 19 as short,

        21 as short, 20 as short, 23 as short,   // face 6
        23 as short, 22 as short, 21 as short
    ]

    // Global OpenGL objects

    val sState = new ShaderState

    val pmvMatrix = new PMVMatrix

    // Shader attributes

    int vertPosLoc          // Location of attribute "vert_position" in vertex shader
    int vertColorLoc        // Location of attribute "vert_color" in vertex shader

    // Fields

    float aspect            // Window aspect ratio

    //---- GLEventListener ----------------------------------------------------

    /**
     * Executed only once at startup
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

        //---- PMV matrix ---------------------------------

        // Initialise the PMV matrix
        pmvMatrix.glMatrixMode( GL_PROJECTION )
        pmvMatrix.glLoadIdentity
        pmvMatrix.glMatrixMode( GL_MODELVIEW )
        pmvMatrix.glLoadIdentity

        // Define first uniform matrix
        val pmvMatrixUniform = new GLUniformData( 'pmvMatrix', 4, 4, pmvMatrix.glGetPMvMatrixf )

        // Bind to uniform attribute in vertex shader
        sState.uniform( gl, pmvMatrixUniform )

        //---- Vertex Buffer Objects ----------------------

        // VBO with vertex attributes
        gl.glGenBuffers( 1, vbos, 0 )
        gl.glBindBuffer( GL::GL_ARRAY_BUFFER, vbos.get( 0 ) )
        gl.glBufferData( GL::GL_ARRAY_BUFFER, vertices.length * SIZEOF_FLOAT, newDirectFloatBuffer( vertices ), GL::GL_STATIC_DRAW )
        gl.glBindBuffer( GL::GL_ARRAY_BUFFER, 0 )

        // VBO with vertex indices
        gl.glGenBuffers( 1, ibos, 0 )
        gl.glBindBuffer( GL::GL_ELEMENT_ARRAY_BUFFER, ibos.get( 0 ) )
        gl.glBufferData( GL::GL_ELEMENT_ARRAY_BUFFER, indices.length * SIZEOF_SHORT, newDirectShortBuffer( indices ), GL::GL_STATIC_DRAW )
        gl.glBindBuffer( GL::GL_ELEMENT_ARRAY_BUFFER, 0 )

        //---- Vertex Array Objects -----------------------

        // Create VAO id
        gl.glGenVertexArrays( 1, vaos, 0 )

        // Bind VAO to Context in order to capture state
        gl.glBindVertexArray( vaos.get( 0 ) )

        val stride = 6 * SIZEOF_FLOAT       // six float attributes per vertex: x,y,z, r,g,b

        // Define structure of vertices VBO
        gl.glBindBuffer( GL::GL_ARRAY_BUFFER, vbos.get( 0 ) )

        gl.glEnableVertexAttribArray( vertPosLoc )
        gl.glVertexAttribPointer( vertPosLoc,   3, GL::GL_FLOAT, false, stride, 0 )

        gl.glEnableVertexAttribArray( vertColorLoc )
        gl.glVertexAttribPointer( vertColorLoc, 3, GL::GL_FLOAT, false, stride, ( 3 * SIZEOF_FLOAT ) )

        // Attach Vertex Index Object to VAO
        gl.glBindBuffer( GL::GL_ELEMENT_ARRAY_BUFFER, ibos.get( 0 ) )

        gl.glBindVertexArray( 0 )

        //---- General setup ------------------------------

        // Clear screen to grey
        gl.glClearColor( 0.4f, 0.4f, 0.4f, 0f )

        // Setup the depth buffer and enable the depth testing
        gl.glEnable( GL::GL_DEPTH_TEST )        // enables depth testing
        gl.glClearDepth( 1.0f )                 // clear z-buffer to the farthest
        gl.glDepthFunc( GL::GL_LEQUAL )         // the type of depth test to do

        // Enable face culling
        gl.glEnable( GL::GL_CULL_FACE )
        gl.glCullFace( GL::GL_BACK )            // remove back-faces
        gl.glFrontFace( GL::GL_CW )             // front is clockwise

        sState.useProgram( gl, false )

        // Show the completed shader state
        println( Thread::currentThread + ' ' + sState )
    }

    /**
     * Called once at startup (after init()) and every time the window is resized.
     */
    override reshape(GLAutoDrawable drawable, int x, int y, int width, int height)
    {
        println( 'reshape' )

        val gl = drawable.GL.getGL3

        // Compute aspect ratio
        aspect = width / height as float

        // Set view port to cover full screen
        gl.glViewport( 0, 0, width, height )

        // Use shaders
        sState.useProgram( gl, true )

        // Set location in front of camera
        pmvMatrix.glMatrixMode( GL_PROJECTION )
        pmvMatrix.glLoadIdentity
        pmvMatrix.gluPerspective( 45f, aspect, 1f, 100f )

        sState.uniform( gl, sState.getUniform( 'pmvMatrix' ) )

        sState.useProgram( gl, false )
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

        sState.destroy( gl )
    }

    //---- Rendering methods --------------------------------------------------

    /**
     * Update world model
     */
    def private update(GLAutoDrawable drawable)
    {
        pmvMatrix.glMatrixMode( GL_MODELVIEW )
        pmvMatrix.glLoadIdentity

        pmvMatrix.glTranslatef( 0f, 0f, -7f )      // move back object along z axis

        // With an FPSAnimator we can use only frames
        var ang = drawable.animator.totalFPSFrames * 2.5f

        pmvMatrix.glRotatef( ang, 0f, 0f, 1f )
        pmvMatrix.glRotatef( ang, 0f, 1f, 0f )
        pmvMatrix.update
    }

    /**
     * Render world
     */
    def private render(GLAutoDrawable drawable)
    {
        val gl = drawable.getGL().getGL3()

        // Clear screen
        gl.glClear( CLEAR_BUFFER_BITS )

        // Use shaders
        sState.useProgram( gl, true )

        // Pass PMV matrix
        sState.uniform( gl, sState.getUniform( 'pmvMatrix' ) )

        // Bind VAO
        gl.glBindVertexArray( vaos.get( 0 ) )

        // Draw the cube!
        gl.glDrawElements( GL::GL_TRIANGLES, indices.length, GL::GL_UNSIGNED_SHORT, 0L )      // must be GL_UNSIGNED_SHORT!

        gl.glBindVertexArray( 0 )

        // Un-use shaders
        sState.useProgram( gl, false )
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
        val sp = new ShaderProgram
        sp.add( gl, vs, System.err )
        sp.add( gl, fs, System.err )

        sState.attachShaderProgram( gl, sp, true )

        // Extract attribute locations
        vertPosLoc   = sState.getAttribLocation( gl, 'vert_position' )
        vertColorLoc = sState.getAttribLocation( gl, 'vert_color' )
    }
}
