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
        'onetriangle'  -> OneTriangle,
        'animtriangle' -> AnimTriangle,
        'onecube'      -> OneCube
    }

    def run(String[] args) {

        val demoClass = parseArgs( args )
        
        // call very early as suggested by the docs
        GLProfile.initSingleton()

        val app = new Application( demoClass, 400, 400 )

        app.runNewt()
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