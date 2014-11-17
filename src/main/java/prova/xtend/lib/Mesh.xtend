package prova.xtend.lib

import com.jogamp.opengl.util.glsl.ShaderCode
import javax.media.opengl.GL3

/**
 * A collection of ojects that can be drawn on screen
 */
class Mesh
{
    /**
     * All OpenGL [3.1 .. 3.3] core methods.
     */
    val GL3 gl

    /**
     * VAO storing the state of this Mesh
     */
    val int vao

    ShaderCode vertexShader
    
    ShaderCode fragmentShader
    
    //---- Constructor ----------------------------------------------
    
    new(GL3 gl) {
        this.gl = gl

        val int[] vaoId = newIntArrayOfSize( 1 )
        gl.glGenVertexArrays( 1, vaoId, 0 )

        vao = vaoId.get( 0 )
        
        gl.glBindVertexArray( vao )
    }

    //---- Accessors ------------------------------------------------

    def getVertexShader() {
        vertexShader
    }
    def package setVertexShader(ShaderCode vertexShader) {
        this.vertexShader = vertexShader
    }

    
    
    
}