// Private - DO NOT MODIFY !
#macro __CUPIDON_GAUSS_WEIGHTS [0.23693, 0.47863, 0.56889, 0.47863, 0.23693]
#macro __CUPIDON_GAUSS_POINTS [0.04691, 0.23075, 0.5, 0.76925, 0.95309]

// Used to define the Unit to use to calculate the anchor_Speed.
// Is used in the `anchor_Speed` method
enum MOTION_UNIT{
    TIME,
    RATIO,
    STEPS
}