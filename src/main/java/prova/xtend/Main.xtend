package prova.xtend

import javax.media.opengl.GLProfile

import static java.lang.System.*

/**
 * Main entry point in the app.
 */
class Main {

    def static void main(String[] args) {
        new Main().run(args)
    }

    val demos = #{
        'threelines'   -> ThreeLines,
        'onetriangle'  -> OneTriangle,
        'textriangle'  -> TexTriangle,
        'animtriangle' -> AnimTriangle,
        'onecube'      -> OneCube,
        'spincube'     -> SpinCube,
        'spintexcube'  -> SpinTexCube
    }

    def run(String[] args) {

        val demoClass = parseArgs( args )
        
        // call very early as suggested by the docs
        GLProfile.initSingleton()

        val app = new GlApplication( demoClass, 400, 400 )

        app.runNewt( 'OpenGL Demo: ' + demoClass.simpleName )
    }

    def private parseArgs(String[] args) {

        if ( args.length == 0 ) {
            err.println( "Missing argument" )
            exit( 1 )
        }

        // argv[0] is the name of the demo
        val name = args.get( 0 )

        if ( demos.containsKey( name ) ) {
            return demos.get( name )
        }

        err.println( "Wrong demo name" )
        exit( 1 )
    }
}
