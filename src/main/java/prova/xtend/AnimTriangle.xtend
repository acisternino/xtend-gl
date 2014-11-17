package prova.xtend

import com.jogamp.common.nio.Buffers
import com.jogamp.opengl.util.glsl.ShaderCode
import com.jogamp.opengl.util.glsl.ShaderProgram
import com.jogamp.opengl.util.glsl.ShaderState
import javax.media.opengl.DebugGL3
import javax.media.opengl.GL
import javax.media.opengl.GL2ES2
import javax.media.opengl.GLAutoDrawable
import javax.media.opengl.GLEventListener

import static java.lang.Math.sin

/**
 *
 */
class AnimTriangle implements GLEventListener
{
    val static SHADERS_DIR     = 'shaders'
    val static SHADERS_BIN_DIR = SHADERS_DIR + '/bin'

    val static int CLEAR_BUFFER_BITS = GL::GL_COLOR_BUFFER_BIT.bitwiseOr( GL::GL_DEPTH_BUFFER_BIT )

    // Array containing buffer and vertex indices (i.e. names).
    // This is kind of a "directory" of buffer objects where their ID's are stored.

    val int[] vbos  = #[ -1, -1 ]
    val int[] vaoIndices = #[ -1 ]

    // These points will be used to build a VBO and be used to draw a triangle

    val float[] points = #[
         0.0f, 0.0f,      0.0f,
         0.25f, 0.43301f, 0.0f,
         0.5f, 0.0f,      0.0f
    ]

    val float[] colors = #[
        1.0f,  0.0f,  0.0f,
        0.0f,  1.0f,  0.0f,
        0.0f,  0.0f,  1.0f
    ]

    float delta

    // Global OpenGL objects

    val st = new ShaderState

    var int offsetLoc

    //---- GLEventListener ----------------------------------------------------

    /**
     * Called only once at startup.
     */
    override init(GLAutoDrawable drawable)
    {
        println( 'init' )

        // Activate debug pipeline
        drawable.setGL( new DebugGL3( drawable.GL.getGL3 ) )

        delta = ( Math.PI * 2 / 30 ) as float       // degrees per frame
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

        // Vertex shader
        val ShaderCode vs0 = ShaderCode.create( gl, GL2ES2::GL_VERTEX_SHADER, this.class,
            SHADERS_DIR, SHADERS_BIN_DIR, 'animtriangle', true )

        // Fragment shader
        val ShaderCode fs0 = ShaderCode.create( gl, GL2ES2::GL_FRAGMENT_SHADER, this.class,
            SHADERS_DIR, SHADERS_BIN_DIR, 'animtriangle', true )

        // Shader program
        st.setVerbose( false )

        val sp = new ShaderProgram

        sp.add( gl, vs0, System.err )
        sp.add( gl, fs0, System.err )

        st.attachShaderProgram( gl, sp, true )

        val int vPosLoc = st.getAttribLocation( gl, 'vert_position' )
        val int vColLoc = st.getAttribLocation( gl, 'vert_colour' )
        offsetLoc = st.getUniformLocation( gl, 'offset_x' )

        st.useProgram( gl, true )

        // Buffers

        // Generate 2 ids ( vertices and colors )
        gl.glGenBuffers( 2, vbos, 0 )

        // bind first to the current Context
        gl.glBindBuffer( GL::GL_ARRAY_BUFFER, vbos.get( 0 ) )

        // fill it with vertex coordinates
        gl.glBufferData( GL::GL_ARRAY_BUFFER, points.size * Buffers::SIZEOF_FLOAT,
                Buffers.newDirectFloatBuffer( points ), GL::GL_STATIC_DRAW )

        // bind second to the current Context
        gl.glBindBuffer( GL::GL_ARRAY_BUFFER, vbos.get( 1 ) )

        // fill it with vertex colors
        gl.glBufferData( GL::GL_ARRAY_BUFFER, colors.size * Buffers::SIZEOF_FLOAT,
                Buffers.newDirectFloatBuffer( colors ), GL::GL_STATIC_DRAW )

        gl.glBindBuffer( GL::GL_ARRAY_BUFFER, 0 )

        // Create VAO
        gl.glGenVertexArrays( 1, vaoIndices, 0 )
        gl.glBindVertexArray( vaoIndices.get( 0 ) )

        gl.glBindBuffer( GL::GL_ARRAY_BUFFER, vbos.get( 0 ) )
        gl.glVertexAttribPointer( vPosLoc, 3, GL::GL_FLOAT, false, 0, 0 )

        gl.glBindBuffer( GL::GL_ARRAY_BUFFER, vbos.get( 1 ) )
        gl.glVertexAttribPointer( vColLoc, 3, GL::GL_FLOAT, false, 0, 0 )

        gl.glEnableVertexAttribArray( vPosLoc )
        gl.glEnableVertexAttribArray( vColLoc )

        gl.glBindVertexArray( 0 )
    }

    /**
     * Called once for each frame.
     */
    override display(GLAutoDrawable drawable)
    {
        val gl = drawable.getGL().getGL3()

        // Clear screen
        gl.glClear( CLEAR_BUFFER_BITS )

        // Use shaders
        st.useProgram( gl, true )

        val offset = sin( ( drawable.animator.totalFPSFrames % 30 ) * delta ) / 2 - 0.25

        gl.glUniform1f( offsetLoc, offset as float )

        // Bind VAO
        gl.glBindVertexArray( vaoIndices.get( 0 ) )

        // Draw the triangle !
        gl.glDrawArrays( GL::GL_TRIANGLES, 0, 3 )    // Starting from vertex 0; 3 vertices total -> 1 triangle

        gl.glBindVertexArray( 0 )
    }

    /**
     *
     */
    override dispose(GLAutoDrawable drawable)
    {
        println( 'dispose' )
    }

    //---- Private methods ----------------------------------------------------

    def private update(GLAutoDrawable drawable) {
    }

    def private render(GLAutoDrawable drawable) {
    }
}
