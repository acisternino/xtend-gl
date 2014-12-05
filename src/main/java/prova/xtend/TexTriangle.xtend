package prova.xtend

import com.jogamp.opengl.util.glsl.ShaderCode
import com.jogamp.opengl.util.glsl.ShaderProgram
import com.jogamp.opengl.util.glsl.ShaderState
import com.jogamp.opengl.util.texture.TextureData
import com.jogamp.opengl.util.texture.TextureIO
import javax.media.opengl.GL
import javax.media.opengl.GL2ES2
import javax.media.opengl.GL3
import javax.media.opengl.GLAutoDrawable
import javax.media.opengl.GLEventListener
import javax.media.opengl.GLPipelineFactory

import static com.google.common.io.Resources.*
import static com.jogamp.common.nio.Buffers.*

/**
 * Simple 2D textured triangle.
 */
class TexTriangle implements GLEventListener
{
    val static SHADERS_DIR     = 'shaders'
    val static SHADERS_BIN_DIR = SHADERS_DIR + '/bin'
    val static SHADERS_BASE_NAME = TexTriangle.simpleName.toLowerCase

    val static CLEAR_BUFFER_BITS = GL::GL_COLOR_BUFFER_BIT.bitwiseOr( GL::GL_DEPTH_BUFFER_BIT )

    val static TEXTURE_NAME = 'Wood_texture_by_shadowh3.jpg'

    // Array containing buffer indices (i.e. names).
    // This is kind of a "directory" of buffer objects where their ID's are stored.

    val vbos = newIntArrayOfSize( 2 )       // for Vertex Buffer Objects
    val vaos = newIntArrayOfSize( 1 )       // for Vertex Array  Objects
    val texs = newIntArrayOfSize( 1 )       // for Texture       Objects

    // These vertices will be used to build a VBO to draw a triangle

    val float[] vertices = #[
    //     X      Y    Z
        -0.7f, -0.5f,  0f,
         0.0f,  0.6f,  0f,
         0.7f, -0.5f,  0f
    ]

    val float[] texCoords = #[
    //    S      T
        0.0f,  0.0f,
        0.5f,  1.0f,
        1.0f,  0.0f
    ]

    // Global OpenGL objects

    val sState = new ShaderState

    var TextureData texData

    // Shader attributes

    int vertPosLoc              // Location of attribute "vert_position" in vertex shader
    int vertTexCoordLoc         // Location of attribute "vert_tex_coord" in vertex shader

    int textureUniformLoc       // Location of the "tex" texture uniform in fragment shader

    //---- GLEventListener ----------------------------------------------------

    /**
     * Called only once at startup.
     */
    override init(GLAutoDrawable drawable)
    {
        println( '[' + Thread::currentThread + '] GLEventListener init()' )

        // Activate Debug pipeline
        var gl = drawable.GL.getGL3
        try {
            gl = gl.context.setGL( GLPipelineFactory.create( 'javax.media.opengl.Debug', GL3, gl, null ) ) as GL3
        }
        catch ( Exception ex ) {
            ex.printStackTrace
        }

        //---- General setup ------------------------------

        // Clear screen to grey
        gl.glClearColor( 0.4f, 0.4f, 0.4f, 0f )

        //---- Shaders ------------------------------------

        createShaders( gl )
        sState.useProgram( gl, true )

        //---- Texture ------------------------------------

        // Load image file (specify the texture type to automatically handle vertical flipping)
        val image = newInputStreamSupplier( getResource( TexTriangle, TEXTURE_NAME ) ).input
        texData = TextureIO::newTextureData( gl.GLProfile, image, false, TextureIO::JPG )

        // Create texture object
        gl.glGenTextures( 1, texs, 0 )

        gl.glActiveTexture( GL::GL_TEXTURE0 )
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
        gl.glUniform1i( textureUniformLoc, 0 )

        // Define parameters for currently bound texture
        gl.glTexParameteri( GL::GL_TEXTURE_2D, GL::GL_TEXTURE_WRAP_S,     GL::GL_REPEAT )
        gl.glTexParameteri( GL::GL_TEXTURE_2D, GL::GL_TEXTURE_WRAP_T,     GL::GL_REPEAT )
        gl.glTexParameteri( GL::GL_TEXTURE_2D, GL::GL_TEXTURE_MIN_FILTER, GL::GL_LINEAR )
        gl.glTexParameteri( GL::GL_TEXTURE_2D, GL::GL_TEXTURE_MAG_FILTER, GL::GL_LINEAR )

        gl.glBindTexture( GL::GL_TEXTURE_2D, 0 )

        //---- Vertex Buffer Objects ----------------------

        // Generate 2 ids ( vertices and colors )
        gl.glGenBuffers( 2, vbos, 0 )

        // VBO with vertex coordinates
        gl.glBindBuffer( GL::GL_ARRAY_BUFFER, vbos.get( 0 ) )
        gl.glBufferData( GL::GL_ARRAY_BUFFER, vertices.size * SIZEOF_FLOAT, newDirectFloatBuffer( vertices ), GL::GL_STATIC_DRAW )

        // VBO with vertex texture coordinates
        gl.glBindBuffer( GL::GL_ARRAY_BUFFER, vbos.get( 1 ) )
        gl.glBufferData( GL::GL_ARRAY_BUFFER, texCoords.size * SIZEOF_FLOAT, newDirectFloatBuffer( texCoords ), GL::GL_STATIC_DRAW )

        gl.glBindBuffer( GL::GL_ARRAY_BUFFER, 0 )

        //---- Vertex Array Objects -----------------------

        // Create VAO id
        gl.glGenVertexArrays( 1, vaos, 0 )

        // Bind VAO to Context in order to capture state
        gl.glBindVertexArray( vaos.get( 0 ) )

        // Define structure of vertices VBO
        gl.glBindBuffer( GL::GL_ARRAY_BUFFER, vbos.get( 0 ) )
        gl.glEnableVertexAttribArray( vertPosLoc )
        gl.glVertexAttribPointer( vertPosLoc, 3, GL::GL_FLOAT, false, 0, 0 )

        // Define structure of texture VBO
        gl.glBindBuffer( GL::GL_ARRAY_BUFFER, vbos.get( 1 ) )
        gl.glEnableVertexAttribArray( vertTexCoordLoc )
        gl.glVertexAttribPointer( vertTexCoordLoc, 2, GL::GL_FLOAT, false, 0, 0 )

        //---- Reset state --------------------------------

        gl.glBindVertexArray( 0 )
        sState.useProgram( gl, false )
    }

    /**
     * Called once at startup (after init()) and every time the window is resized.
     */
    override reshape(GLAutoDrawable drawable, int x, int y, int width, int height)
    {
        println( '[' + Thread::currentThread + '] GLEventListener reshape()' )
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
        println( '[' + Thread::currentThread + '] GLEventListener dispose()' )

        val gl = drawable.GL.getGL3

        sState.destroy( gl )
    }

    //---- Rendering methods --------------------------------------------------

    /**
     * Update world model
     */
    def private update(GLAutoDrawable drawable)
    {
        // Nothing to do
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

        // Draw the triangle !
        gl.glDrawArrays( GL::GL_TRIANGLES, 0, 3 )    // Starting from vertex 0; 3 vertices total -> 1 triangle

        // Clean-up
        gl.glBindTexture( GL::GL_TEXTURE_2D, 0 )
        gl.glBindVertexArray( 0 )

        sState.useProgram( gl, false )
    }

    //---- Support methods ----------------------------------------------------

    def private createShaders(GL3 gl)
    {
        println( '[' + Thread::currentThread + '] createShaders()' )

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
        vertPosLoc      = sState.getAttribLocation( gl, 'vert_position' )
        vertTexCoordLoc = sState.getAttribLocation( gl, 'vert_tex_coord' )

        textureUniformLoc = sState.getUniformLocation( gl, 'tex' )
    }

}
