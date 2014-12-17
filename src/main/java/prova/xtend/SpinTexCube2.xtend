package prova.xtend

import com.jogamp.newt.event.KeyEvent
import com.jogamp.newt.event.KeyListener
import com.jogamp.newt.opengl.GLWindow
import com.jogamp.opengl.util.glsl.ShaderCode
import com.jogamp.opengl.util.glsl.ShaderProgram
import com.jogamp.opengl.util.glsl.ShaderState
import com.jogamp.opengl.util.texture.TextureData
import com.jogamp.opengl.util.texture.TextureIO
import javax.media.opengl.GL
import javax.media.opengl.GL2ES2
import javax.media.opengl.GL3
import javax.media.opengl.GLAutoDrawable
import javax.media.opengl.GLPipelineFactory

import static com.google.common.io.Resources.*
import static com.jogamp.common.nio.Buffers.*
import static com.jogamp.opengl.math.FloatUtil.*

/**
 * Spinning textured cube.
 */
class SpinTexCube2 extends GlDemo implements KeyListener
{
    val static SHADERS_DIR       = 'shaders'
    val static SHADERS_BIN_DIR   = SHADERS_DIR + '/bin'
    val static SHADERS_BASE_NAME = SpinTexCube2.simpleName.toLowerCase

    val static CLEAR_BUFFER_BITS = GL::GL_COLOR_BUFFER_BIT.bitwiseOr( GL::GL_DEPTH_BUFFER_BIT )

    val static TEXTURE_NAME = 'grey_square128.png'

    val static DEG_TO_RAD = 0.0174532925199432f

    // Array containing buffer and vertex indices (i.e. names).
    // This is kind of a "directory" of buffer objects where their ID's are stored.

    val vbos = newIntArrayOfSize( 1 )       // for Vertex Buffer Objects
    val ibos = newIntArrayOfSize( 1 )       // for Index  Buffer Objects
    val vaos = newIntArrayOfSize( 1 )       // for Vertex Array  Objects
    val texs = newIntArrayOfSize( 1 )       // for Texture       Objects

    // These vertices will be used to build a VBO to draw a XZ plane

    val float[] vertices = #[
    //    X     Y    Z       S    T
        -64f,  64f,  0f,     0f, 64f,     // 0
         64f,  64f,  0f,    64f, 64f,     // 1
         64f,   0f,  0f,    64f, 32f,     // 2
         64f, -64f,  0f,    64f,  0f,     // 3
        -64f, -64f,  0f,     0f,  0f,     // 4
        -64f,   0f,  0f,     0f, 32f      // 5
    ]

    val short[] indices = #[
         0 as short,  1 as short,  5 as short,      // upper rectangle
         1 as short,  2 as short,  5 as short,

         5 as short,  2 as short,  4 as short,      // lower rectangle
         4 as short,  2 as short,  3 as short
    ]

    // Global OpenGL objects

    val sState = new ShaderState

    var TextureData texData

    // Shader attributes

    int vertPosLoc              // Location of attribute "vert_position" in vertex shader
    int vertTexCoordLoc         // Location of attribute "vert_tex_coord" in vertex shader

    int textureUniformLoc       // Location of the "tex" texture uniform in fragment shader

    // Transformation matrices

    val modelViewMatrix  = newFloatArrayOfSize( 16 )
    val projectionMatrix = newFloatArrayOfSize( 16 )

    // Fields

    var aspect = 1.0f           // Window aspect ratio

    //---- GLEventListener ----------------------------------------------------

    /**
     * Executed only once at startup
     */
    override init(GLAutoDrawable drawable)
    {
        println( Thread::currentThread + ' - GLEventListener init()' )

        // Activate Debug pipeline
        var gl = drawable.GL.getGL3
        try {
            gl = gl.context.setGL( GLPipelineFactory.create( 'javax.media.opengl.Debug', GL3, gl, null ) ) as GL3
        }
        catch ( Exception ex ) {
            ex.printStackTrace
        }

        //---- Shaders ------------------------------------

        createShaders( gl )
        sState.useProgram( gl, true )

        //---- Texture ------------------------------------

        // Load image file (specify the texture type to automatically handle vertical flipping)
        val image = newInputStreamSupplier( getResource( SpinTexCube2, TEXTURE_NAME ) ).input
        texData = TextureIO::newTextureData( gl.GLProfile, image, false, TextureIO::PNG )

        // Create texture object
        gl.glGenTextures( 1, texs, 0 )

        gl.glActiveTexture( GL::GL_TEXTURE0 )           // Texture Unit 0
        gl.glBindTexture( GL::GL_TEXTURE_2D, texs.get( 0 ) )

        // Load texture data
        gl.glTexImage2D( GL::GL_TEXTURE_2D, 0,
            texData.internalFormat,
            texData.width,
            texData.height,
            0,
            texData.pixelFormat,
            texData.pixelType,
            texData.buffer
        )

        // Specify matching Uniform for this texture
        gl.glUniform1i( textureUniformLoc, 0 )

        // Define parameters for currently bound texture
        gl.glTexParameteri( GL::GL_TEXTURE_2D, GL::GL_TEXTURE_WRAP_S,     GL::GL_REPEAT )
        gl.glTexParameteri( GL::GL_TEXTURE_2D, GL::GL_TEXTURE_WRAP_T,     GL::GL_REPEAT )
        gl.glTexParameteri( GL::GL_TEXTURE_2D, GL::GL_TEXTURE_MIN_FILTER, GL::GL_LINEAR )
        gl.glTexParameteri( GL::GL_TEXTURE_2D, GL::GL_TEXTURE_MAG_FILTER, GL::GL_LINEAR )

        //gl.glBindTexture( GL::GL_TEXTURE_2D, 0 )

        //---- Matrices -----------------------------------

        // Translate plane 10 units away from origin
        var modelMatrix = newFloatArrayOfSize( 16 )
        makeTranslation( modelMatrix, true, 0f, 0f, -10f )

        // Position camera
        var viewMatrix = newFloatArrayOfSize( 16 )
        makeLookAt( viewMatrix, 0,
            #[ 0f, 3f, 10f ], 0,    // eye
            #[ 0f, 3f,  0f ], 0,    // target
            #[ 0f, 4f, 10f ], 0,    // up
            newFloatArrayOfSize( 16 )
        )

        // Create ModelView matrix
        multMatrix( viewMatrix, modelMatrix, modelViewMatrix )

        println( Thread::currentThread + ' - ModelView matrix:' )
        println( matrixToString( null, 'R', '%5.2f', modelViewMatrix, 0, 4, 4, false ) )

        // Create Projection matrix
        makePerspective(
            projectionMatrix, 0,
            true,
            60f * DEG_TO_RAD,   // fovy (radians)
            aspect,             // aspect ratio
            0.1f,               // near plane
            100f                // far plane
        )

        println( Thread::currentThread + ' - Projection matrix:' )
        println( matrixToString( null, 'R', '%5.2f', projectionMatrix, 0, 4, 4, false ) )

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

        val stride = 5 * SIZEOF_FLOAT       // five float attributes per vertex: x,y,z, s,t

        // Define structure of vertices VBO
        gl.glBindBuffer( GL::GL_ARRAY_BUFFER, vbos.get( 0 ) )

        gl.glEnableVertexAttribArray( vertPosLoc )
        gl.glVertexAttribPointer( vertPosLoc,   3, GL::GL_FLOAT, false, stride, 0 )

        gl.glEnableVertexAttribArray( vertTexCoordLoc )
        gl.glVertexAttribPointer( vertTexCoordLoc, 2, GL::GL_FLOAT, false, stride, ( 3 * SIZEOF_FLOAT ) )

        // Attach Vertex Index Object to VAO
        gl.glBindBuffer( GL::GL_ELEMENT_ARRAY_BUFFER, ibos.get( 0 ) )

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

        //---- Reset state --------------------------------

        gl.glBindVertexArray( 0 )
        gl.glBindTexture( GL::GL_TEXTURE_2D, 0 )
        sState.useProgram( gl, false )
    }

    /**
     * Called once at startup (after init()) and every time the window is resized.
     */
    override reshape(GLAutoDrawable drawable, int x, int y, int width, int height)
    {
        println( Thread::currentThread + ' - GLEventListener reshape()' )

        val gl = drawable.GL.getGL3

        // Compute aspect ratio
        aspect = width / height as float

        // Set view port to cover full screen
        gl.glViewport( 0, 0, width, height )
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
        println( Thread::currentThread + ' - GLEventListener dispose()' )

        val gl = drawable.GL.getGL3

        sState.destroy( gl )
    }

    //---- Rendering methods --------------------------------------------------

    /**
     * Update world model
     */
    def private update(GLAutoDrawable drawable)
    {
    }

    /**
     * Render world
     */
    def private render(GLAutoDrawable drawable)
    {
        val gl = drawable.GL.getGL3

        // Clear screen
        gl.glClear( CLEAR_BUFFER_BITS )

        // Use shaders
        sState.useProgram( gl, true )

        // Bind VAO & Texture
        gl.glBindVertexArray( vaos.get( 0 ) )
        gl.glBindTexture( GL::GL_TEXTURE_2D, texs.get( 0 ) )

        // Draw the plane!
        gl.glDrawElements( GL::GL_TRIANGLES, indices.length, GL::GL_UNSIGNED_SHORT, 0L )      // must be GL_UNSIGNED_SHORT!

        // Clean-up
        gl.glBindTexture( GL::GL_TEXTURE_2D, 0 )
        gl.glBindVertexArray( 0 )

        sState.useProgram( gl, false )
    }

    //---- KeyListener --------------------------------------------------------

    override keyPressed(KeyEvent ke)
    {
        println( Thread::currentThread + ' - keyPressed: ' + ke )
    }

    override keyReleased(KeyEvent ke)
    {
        println( Thread::currentThread + ' - keyReleased: ' + ke )
    }

    //---- Support methods ----------------------------------------------------

    def private createShaders(GL3 gl)
    {
        // Vertex shader
        var vshader = gl.glCreateShader( GL::GL_VERTEX_SHADER )
        
        val vsCode = ShaderCode.create( gl, GL2ES2::GL_VERTEX_SHADER, this.class, SHADERS_DIR, SHADERS_BIN_DIR, SHADERS_BASE_NAME, true )

        
        
        
        
        
        
        
        
        
        
        
        var url = getResource( SpinTexCube2, SHADERS_DIR + '/' + SHADERS_BASE_NAME + '.vp' )    // use StandardCharsets::US_ASCII
        println( Thread::currentThread + ' - Loading shader: ' + url )
        
        // or
        String vsSource = ShaderCode.readShaderSource( SpinTexCube2, SHADERS_DIR + '/' + SHADERS_BASE_NAME + '.vp', false )
        // or use method shaderSource() once a ShaderCode object is cretaed
        
        
glShaderSource(vshader, 1, &vertex_shader_source, NULL); // vertex_shader_source is a GLchar* containing glsl shader source code
glCompileShader(vshader);

GLint vertex_compiled;
glGetShaderiv(vshader, GL_COMPILE_STATUS, &vertex_compiled);
if (vertex_compiled != GL_TRUE)
{
    GLsizei log_length = 0;
    GLchar message[1024];
    glGetShaderInfoLog(vshader, 1024, &log_length, message);
    // Write the error to a log
}

        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
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
        vertPosLoc      = sState.getAttribLocation( gl, 'vert_position' )
        vertTexCoordLoc = sState.getAttribLocation( gl, 'vert_tex_coord' )

        textureUniformLoc = sState.getUniformLocation( gl, 'tex' )
    }

    override setWindow(GLWindow window)
    {
        // register ourselves as key listener
        window.addKeyListener( this )
    }

}
