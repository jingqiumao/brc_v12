! $Id: emep_mod.f,v 1.4 2006/06/06 14:26:01 bmy Exp $
      MODULE EMEP_MOD
!
!******************************************************************************
!  Module EMEP_MOD contains variables and routines to read the EMEP European 
!  anthropogenic emission inventory for CO, NOz, and some NMVOCs.  The EMEP 
!  files come from Marion Auvray and Isabelle Bey at EPFL. 
!  (bdf, bmy, 11/1/05, 5/30/06)
!
!  Module Variables:
!  ============================================================================
!  (1 ) EUROPE_MASK   (REAL*8) : Array used to mask out the Europe region
!  (2 ) EMEP_EMISS_AN (REAL*8) : EMEP anthropogenic emissions [molec/cm2/s]
! 
!  Module Routines:
!  ============================================================================
!  (1 ) GET_EUROPE_MASK        : Gets the value of the Europe mask at (I,J) 
!  (2 ) GET_EMEP_ANTHRO        : Gets emissions at (I,J) for EMEP species 
!  (3 ) EMISS_EMEP             : Reads EMEP emissions from disk once per year
!  (4 ) EMEP_SCALE_FUTURE      : Applies IPCC future scale factors to EMEP
!  (5 ) INIT_EMEP              : Allocates and zeroes module arrays
!  (6 ) CLEANUP_EMEP           : Dealocates module arrays
!
!  GEOS-CHEM modules referenced by "emep_mod.f"
!  ============================================================================
!  (1 ) bpch2_mod.f            : Module w/ routines for binary punch file I/O
!  (2 ) directory_mod.f        : Module w/ GEOS-CHEM data & met field dirs
!  (3 ) error_mod.f            : Module w/ I/O error and NaN check routines
!  (4 ) file_mod.f             : Module w/ file unit numbers and error checks
!  (5 ) future_emissions_mod.f : Module w/ routines for IPCC future emissions
!  (6 ) grid_mod.f             : Module w/ horizontal grid information
!  (7 ) logical_mod.f          : Module w/ GEOS-CHEM logical switches
!  (8 ) regrid_1x1_mod.f       : Module w/ routines to regrid 1x1 data  
!  (9 ) time_mod.f             : Module w/ routines for computing time & date
!  (10) tracerid_mod.f         : Module w/ pointers to tracers & emissions  
!
!  References:
!  ============================================================================
!  (1 ) Vestreng, V., and H. Klein (2002), "Emission data reported to UNECE/
!        EMEP: Quality insurance and trend analysis and presentation of Web-
!        Dab, MSC-W Status Rep. 2002", 101 pp., Norw. Meteorol. Inst., Oslo,
!        Norway.  This paper is on the EMEP web site:
!         http://www.emep.int/mscw/mscw_publications.html
!         http://www.emep.int/publ/reports/2002/mscw_note_1_2002.pdf
!  (2 ) Auvray, M., and I. Bey, "Long-Range Transport to Europe: Seasonal 
!        Variations and Implications for the European Ozone Budget", 
!        J. Geophys. Res., 110, D11303, doi: 10.1029/2004JD005503, 2005.
!
!  NOTES: 
!  (1 ) Now only print totals for defined tracers (bmy, 2/6/06)
!  (2 ) Now modified for IPCC future emissions (swu, bmy, 5/30/06)
!******************************************************************************
!
      IMPLICIT NONE

      !=================================================================
      ! MODULE PRIVATE DECLARATIONS -- keep certain internal variables 
      ! and routines from being seen outside "emep_mod.f"
      !=================================================================

      ! Make everything PRIVATE ...
      PRIVATE

      ! ... except these routines
      PUBLIC :: EMISS_EMEP
      PUBLIC :: CLEANUP_EMEP
      PUBLIC :: GET_EUROPE_MASK
      PUBLIC :: GET_EMEP_ANTHRO

      !=================================================================
      ! MODULE VARIABLES 
      !=================================================================

      ! Arrays
      REAL*8,  ALLOCATABLE :: EUROPE_MASK(:,:)
      REAL*8,  ALLOCATABLE :: EMEP_NOx(:,:)
      REAL*8,  ALLOCATABLE :: EMEP_CO(:,:)
      REAL*8,  ALLOCATABLE :: EMEP_ALK4(:,:)
      REAL*8,  ALLOCATABLE :: EMEP_MEK(:,:)
      REAL*8,  ALLOCATABLE :: EMEP_ALD2(:,:)
      REAL*8,  ALLOCATABLE :: EMEP_PRPE(:,:)
      REAL*8,  ALLOCATABLE :: EMEP_C2H6(:,:)

      !=================================================================
      ! MODULE ROUTINES -- follow below the "CONTAINS" statement 
      !=================================================================
      CONTAINS

!------------------------------------------------------------------------------

      FUNCTION GET_EUROPE_MASK( I, J ) RESULT( EUROPE )

!
!******************************************************************************
!  Function GET_EUROPE_MASK returns the value of the EUROPE mask for EMEP
!  emissions at grid box (I,J).  MASK=1 if (I,J) is in the European region, 
!  or MASK=0 otherwise. (bdf, bmy, 11/1/05)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) I (INTEGER) : GEOS-CHEM longitude index 
!  (2 ) J (INTEGER) : GEOS-CHEM latitude  index 
!
!  NOTES:
!******************************************************************************
!
      ! Arguments
      INTEGER, INTENT(IN) :: I, J

      ! Function return value
      REAL*8              :: EUROPE

      !=================================================================
      ! GET_EUROPE_MASK begins here!
      !=================================================================
      EUROPE = EUROPE_MASK(I,J)

      ! Return to calling program
      END FUNCTION GET_EUROPE_MASK

!------------------------------------------------------------------------------

      FUNCTION GET_EMEP_ANTHRO( I, J, N ) RESULT( EMEP )
!
!******************************************************************************
!  Function GET_EMEP_ANTHRO returns the EMEP emission for GEOS-CHEM grid box 
!  (I,J) and tracer N. (bdf, bmy, 11/1/05)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) I (INTEGER) : GEOS-CHEM longitude index
!  (2 ) J (INTEGER) : GEOS-CHEM latitude index
!  (3 ) N (INTEGER) : GEOS-CHEM tracer number
!  
!  NOTES:
!******************************************************************************
!
      ! References to F90 modules
      USE TRACERID_MOD, ONLY : IDTNOX,  IDTCO,   IDTALK4, IDTMEK
      USE TRACERID_MOD, ONLY : IDTALD2, IDTPRPE, IDTC2H6

      ! Arguments
      INTEGER, INTENT(IN)   :: I, J, N

      ! Function return value
      REAL*8                :: EMEP
      
      !=================================================================
      ! GET_EMEP_ANTHRO begins here!
      !=================================================================

      ! NOx
      IF ( N  == IDTNOX ) THEN
         EMEP = EMEP_NOx(I,J)

      ! CO
      ELSE IF ( N == IDTCO ) THEN
         EMEP = EMEP_CO(I,J)

      ! ALK4 (>= C4 alkanes)
      ELSE IF ( N == IDTALK4 ) THEN
         EMEP = EMEP_ALK4(I,J)

      ! MEK
      ELSE IF ( N == IDTMEK ) THEN
         EMEP = EMEP_MEK(I,J)

      ! ALD2 (acetaldehyde)
      ELSE IF ( N == IDTALD2 ) THEN
         EMEP = EMEP_ALD2(I,J)

      ! PRPE (>= C3 alkenes)
      ELSE IF ( N == IDTPRPE ) THEN
         EMEP = EMEP_PRPE(I,J)

      ! C2H6 
      ELSE IF ( N == IDTC2H6 ) THEN
         EMEP = EMEP_C2H6(I,J)

      ! Otherwise return a negative value to indicate
      ! that there are no EMEP emissions for tracer N
      ELSE
         EMEP = -1d0

      ENDIF

      ! Return to calling program
      END FUNCTION GET_EMEP_ANTHRO

!------------------------------------------------------------------------------

      SUBROUTINE EMISS_EMEP
!
!******************************************************************************
!  Subroutine EMISS_EMEP reads the EMEP emission fields at 1x1 
!  resolution and regrids them to the current model resolution.
!  (bdf, bmy, 11/1/05, 5/30/06)
!
!  NOTES:
!  (1 ) Modified for IPCC future emissions.  Now references LFUTURE from
!        "logical_mod.f". (bmy, 5/30/06)
!******************************************************************************
!
      ! References to F90 modules
      USE BPCH2_MOD,      ONLY : GET_TAU0,     OPEN_BPCH2_FOR_READ
      USE FILE_MOD,       ONLY : IU_FILE,      IOERROR
      USE DIRECTORY_MOD,  ONLY : DATA_DIR_1x1 
      USE LOGICAL_MOD,    ONLY : LFUTURE
      USE REGRID_1x1_MOD, ONLY : DO_REGRID_1x1
      USE TIME_MOD,       ONLY : EXPAND_DATE,  GET_YEAR

#     include "CMN_SIZE"       ! Size parameters

      ! Local variables
      LOGICAL, SAVE           :: FIRST = .TRUE.
      INTEGER                 :: EMEP_NYMD, EMEP_YEAR
      REAL*8                  :: EMEP_TAU,  TAU0
      CHARACTER(LEN=255)      :: FILENAME

      ! For bpch file format
      INTEGER                 :: I,  J,  L,  N,  IOS
      INTEGER                 :: NTRACER,   NSKIP
      INTEGER                 :: HALFPOLAR, CENTER180
      INTEGER                 :: NI,        NJ,        NL
      INTEGER                 :: IFIRST,    JFIRST,    LFIRST
      REAL*4                  :: ARRAY(I1x1,J1x1,1)
      REAL*4                  :: LONRES,    LATRES
      REAL*8                  :: ZTAU0,     ZTAU1
      CHARACTER(LEN=20)       :: MODELNAME
      CHARACTER(LEN=40)       :: CATEGORY
      CHARACTER(LEN=40)       :: UNIT     
      CHARACTER(LEN=40)       :: RESERVED

      !=================================================================
      ! EMISS_EMEP begins here!
      !=================================================================

      ! First-time initialization
      IF ( FIRST ) THEN
         CALL INIT_EMEP
         FIRST = .FALSE.
      ENDIF

      ! 1x1 file name
      FILENAME  = TRIM( DATA_DIR_1x1 ) // 
     &            'EMEP_200510/EMEP.geos.1x1.YYYY'

      ! EMEP data is only defined from 1985-2000 (add new years later)
      EMEP_YEAR = MAX( MIN( GET_YEAR(), 2000 ), 1985 )

      ! YYYYMMDD value for 1st day of EMEP_YEAR
      EMEP_NYMD = ( EMEP_YEAR * 10000 ) + 0101 

      ! TAU0 value corresponding to EMEP_NYMD
      EMEP_TAU  = GET_TAU0( 1, 1, EMEP_YEAR )
         
      ! Expand filename
      CALL EXPAND_DATE( FILENAME, EMEP_NYMD, 000000 )
         
      ! Echo info
      WRITE( 6, 100 ) TRIM( FILENAME )
 100  FORMAT( '     - EMISS_EMEP: Reading ', a )

      !=================================================================
      ! Read data at 1x1 resolution and regrid to current grid size
      !=================================================================

      ! Open file
      CALL OPEN_BPCH2_FOR_READ( IU_FILE, FILENAME )

      ! Read the entire file in one pass (for I/O optimization)
      DO 

         ! Read 1st data block header line
         READ( IU_FILE, IOSTAT=IOS ) 
     &     MODELNAME, LONRES, LATRES, HALFPOLAR, CENTER180

         ! Check for EOF or errors
         IF ( IOS < 0 ) EXIT
         IF ( IOS > 0 ) CALL IOERROR( IOS, IU_FILE, 'emiss_emep:2' )

         ! Read 2nd data block header line
         READ( IU_FILE, IOSTAT=IOS ) 
     &        CATEGORY, NTRACER,  UNIT, ZTAU0,  ZTAU1,  RESERVED,
     &        NI,       NJ,       NL,   IFIRST, JFIRST, LFIRST, NSKIP

         ! Error check
         IF ( IOS /= 0 ) CALL IOERROR( IOS, IU_FILE, 'emiss_emep:3' )

         ! Read data [molec/cm2/s] or [atoms C/cm2/s]
         READ( IU_FILE, IOSTAT=IOS ) 
     &        ( ( ( ARRAY(I,J,L), I=1,NI ), J=1,NJ ), L=1,NL )

         ! Error check
         IF ( IOS /= 0 ) CALL IOERROR( IOS, IU_FILE, 'emiss_emep:4' )

         ! Regrid data from 1x1
         SELECT CASE ( NTRACER )

            ! NOx [molec/cm2/s]
            CASE( 1  )
               CALL DO_REGRID_1x1( UNIT, ARRAY, EMEP_NOx  )

            ! CO [molec/cm2/s]
            CASE( 4  )
               CALL DO_REGRID_1x1( UNIT, ARRAY, EMEP_CO   )

            ! ALK4 [atoms C/cm2/s]
            CASE( 5  )
               CALL DO_REGRID_1x1( UNIT, ARRAY, EMEP_ALK4 )

            ! MEK [atoms C/cm2/s]
            CASE( 10 )
               CALL DO_REGRID_1x1( UNIT, ARRAY, EMEP_MEK  )

            ! ALD2 [atoms C/cm2/s]
            CASE( 11 )
               CALL DO_REGRID_1x1( UNIT, ARRAY, EMEP_ALD2 )

            ! PRPE [atoms C/cm2/s]
            CASE( 18 )
               CALL DO_REGRID_1x1( UNIT, ARRAY, EMEP_PRPE )

            ! C2H6 [atoms C/cm2/s]
            CASE( 21 )
               CALL DO_REGRID_1x1( UNIT, ARRAY, EMEP_C2H6 )

            CASE DEFAULT
               ! Nothing

         END SELECT

      ENDDO

      ! Close file
      CLOSE( IU_FILE )

      !=================================================================
      ! Compute IPCC future emissions (if necessary)
      !=================================================================
      IF ( LFUTURE ) THEN 
         CALL EMEP_SCALE_FUTURE
      ENDIF

      !=================================================================
      ! Print emission totals
      !=================================================================

      ! Print totals for EMEP_YEAR
      CALL TOTAL_ANTHRO_TG( EMEP_YEAR )

      ! Return to calling program
      END SUBROUTINE EMISS_EMEP

!------------------------------------------------------------------------------

      SUBROUTINE EMEP_SCALE_FUTURE
!
!******************************************************************************
!  Subroutine EMEP_SCALE_FUTURE applies the IPCC future scale factors to 
!  the EMEP anthropogenic emissions. (swu, bmy, 5/30/06)
!
!  NOTES:
!******************************************************************************
!
      ! References to F90 modules
      USE FUTURE_EMISSIONS_MOD, ONLY : GET_FUTURE_SCALE_ALK4ff
      USE FUTURE_EMISSIONS_MOD, ONLY : GET_FUTURE_SCALE_C2H6ff
      USE FUTURE_EMISSIONS_MOD, ONLY : GET_FUTURE_SCALE_COff
      USE FUTURE_EMISSIONS_MOD, ONLY : GET_FUTURE_SCALE_NOxff
      USE FUTURE_EMISSIONS_MOD, ONLY : GET_FUTURE_SCALE_PRPEff
      USE FUTURE_EMISSIONS_MOD, ONLY : GET_FUTURE_SCALE_TONEff
      USE FUTURE_EMISSIONS_MOD, ONLY : GET_FUTURE_SCALE_VOCff

#     include "CMN_SIZE"             ! Size parameters

      ! Local variables
      INTEGER                       :: I, J

      !=================================================================
      ! EMEP_SCALE_FUTURE begins here!
      !=================================================================

!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I, J )
      DO J = 1, JJPAR
      DO I = 1, IIPAR

         ! Future NOx [molec/cm2/s]
         EMEP_NOx(I,J)  = EMEP_NOx(I,J)                   * 
     &                    GET_FUTURE_SCALE_NOxff( I, J )

         ! Future CO [molec/cm2/s]
         EMEP_CO(I,J)   = EMEP_CO(I,J)                    *
     &                    GET_FUTURE_SCALE_COff( I, J )

         ! Future ALK4 [atoms C/cm2/s]
         EMEP_ALK4(I,J) = EMEP_ALK4(I,J)                  *
     &                    GET_FUTURE_SCALE_ALK4ff( I, J )
         
         ! Future MEK [atoms C/cm2/s]
         EMEP_MEK(I,J)  = EMEP_MEK(I,J)                   *
     &                    GET_FUTURE_SCALE_TONEff( I, J )     

         ! Future ALD2 [atoms C/cm2/s]
         EMEP_ALD2(I,J) = EMEP_ALD2(I,J)                  *
     &                    GET_FUTURE_SCALE_VOCff( I, J )
     
         ! Future PRPE [atoms C/cm2/s]
         EMEP_PRPE(I,J) = EMEP_PRPE(I,J)                  *
     &                    GET_FUTURE_SCALE_PRPEff( I, J )

         ! Future C2H6 [atoms C/cm2/s]
         EMEP_C2H6(I,J) = EMEP_C2H6(I,J)                  *
     &                    GET_FUTURE_SCALE_C2H6ff( I, J )
      ENDDO
      ENDDO
!$OMP END PARALLEL DO

      ! Return to calling program
      END SUBROUTINE EMEP_SCALE_FUTURE

!------------------------------------------------------------------------------

      SUBROUTINE TOTAL_ANTHRO_TG( EMEP_YEAR )
!
!******************************************************************************
!  Subroutine TOTAL_ANTHRO_TG prints the amount of EPA/NEI anthropogenic
!  emissions that are emitted each month in Tg or Tg C. 
!  (rch, bmy, 11/10/04, 2/6/06)
!  
!  Arguments as Input:
!  ============================================================================
!  (1  ) FFARRAY  (REAL*8 ) : Fossil Fuel CO emissions [molec (C)/cm2/month]
!  (2-4) IX,JX,LX (INTEGER) : Dimensions of FFARRAY 
!  (5  ) MOLWT    (REAL*8 ) : Molecular wt [kg/mole] for the given tracer
!  (6  ) NAME     (REAL*8 ) : Tracer name
!  (7  ) NSEASON  (INTEGER) : Number of the season, for seasonal NOx/SOX
!
!  NOTES:
!  (1 ) Now make sure all USE statements are USE, ONLY (bmy, 10/3/05)
!  (2 ) Now replace FMOL with TRACER_MW_KG (bmy, 10/25/05) 
!  (3 ) Now only print totals of defined tracers; other totals will be
!        printed as zeroes. (bmy, 2/6/06)
!******************************************************************************
!
      ! References to F90 modules
      USE GRID_MOD,     ONLY : GET_AREA_CM2
      USE TRACER_MOD,   ONLY : XNUMOL
      USE TRACERID_MOD, ONLY : IDTNOX,  IDTCO,   IDTALK4, IDTMEK
      USE TRACERID_MOD, ONLY : IDTALD2, IDTPRPE, IDTC2H6

#     include "CMN_SIZE"     ! Size parameters

      ! Arguments
      INTEGER, INTENT(IN)   :: EMEP_YEAR

      ! Local variables
      INTEGER               :: I, J
      REAL*8                :: A,   B(7), NOX,  CO,  ALK4
      REAL*8                :: MEK, ALD2, PRPE, C2H6
      CHARACTER(LEN=3)      :: UNIT

      !=================================================================
      ! TOTAL_ANTHRO_TG begins here!
      !=================================================================

      ! Fancy output
      WRITE( 6, '(a)' ) REPEAT( '=', 79 )
      WRITE( 6, 100  )
 100  FORMAT( 'E M E P   E U R O P E A N   E M I S S I O N S', / )

      !----------------
      ! Sum emissions
      !----------------
      
      ! Define conversion factors for kg/molec
      ! (Undefined tracers will be zero)
      B(:) = 0d0
      IF ( IDTNOx  > 0 ) B(1) = 1d0 / ( 6.0225d23 / 14d-3 )  ! Tg N
      IF ( IDTCO   > 0 ) B(2) = 1d0 / XNUMOL(IDTCO  )
      IF ( IDTALK4 > 0 ) B(3) = 1d0 / XNUMOL(IDTALK4)
      IF ( IDTMEK  > 0 ) B(4) = 1d0 / XNUMOL(IDTMEK )
      IF ( IDTALD2 > 0 ) B(5) = 1d0 / XNUMOL(IDTALD2)
      IF ( IDTPRPE > 0 ) B(6) = 1d0 / XNUMOL(IDTPRPE)
      IF ( IDTC2H6 > 0 ) B(7) = 1d0 / XNUMOL(IDTC2H6)

      ! Summing variables
      NOX      = 0d0   
      CO       = 0d0 
      ALK4     = 0d0 
      MEK      = 0d0 
      ALD2     = 0d0 
      PRPE     = 0d0 
      C2H6     = 0d0 

      ! Loop over latitudes
      DO J = 1, JJPAR
            
         ! Surface area [cm2] * seconds in this year 
         ! Multiply by 1d-9 to convert from [kg] to [Tg]
         A = GET_AREA_CM2( J ) * 365.25d0 * 86400d0 * 1d-9 
         
         ! Loop over longitudes
         DO I = 1, IIPAR

            ! Sum emissions (list NOx as Tg N)
            NOX  = NOX  + EMEP_NOX (I,J) * A * B(1)
            CO   = CO   + EMEP_CO  (I,J) * A * B(2) 
            ALK4 = ALK4 + EMEP_ALK4(I,J) * A * B(3) 
            MEK  = MEK  + EMEP_MEK (I,J) * A * B(4) 
            ALD2 = ALD2 + EMEP_ALD2(I,J) * A * B(5) 
            PRPE = PRPE + EMEP_PRPE(I,J) * A * B(6) 
            C2H6 = C2H6 + EMEP_C2H6(I,J) * A * B(7) 
         ENDDO
      ENDDO
 
      !----------------
      ! Print sums
      !----------------

      ! Print totals in [kg]
      WRITE( 6, 110   ) 'NOx ', EMEP_YEAR, NOx,  ' N'
      WRITE( 6, 110   ) 'CO  ', EMEP_YEAR, CO,   '  '
      WRITE( 6, 110   ) 'ALK4', EMEP_YEAR, ALK4, ' C'
      WRITE( 6, 110   ) 'MEK ', EMEP_YEAR, MEK,  ' C'
      WRITE( 6, 110   ) 'ALD2', EMEP_YEAR, ALD2, ' C'
      WRITE( 6, 110   ) 'PRPE', EMEP_YEAR, PRPE, ' C'
      WRITE( 6, 110   ) 'C2H6', EMEP_YEAR, C2H6, ' C'
 110  FORMAT( 'EMEP anthropogenic ', a4, ' for ', i4, 
     &        ': ', f13.6, ' Tg', a2 )

      ! Fancy output
      WRITE( 6, '(a)' ) REPEAT( '=', 79 )

      ! Return to calling program
      END SUBROUTINE TOTAL_ANTHRO_TG

!------------------------------------------------------------------------------

      SUBROUTINE INIT_EMEP
!
!******************************************************************************
!  Subroutine INIT_EMEP allocates and zeroes EMEP module arrays, and also
!  creates the mask which defines the European region (bdf, bmy, 11/1/01) 
!
!  NOTES:
!******************************************************************************
!
      ! References to F90 modules
      USE ERROR_MOD,   ONLY : ALLOC_ERR
      USE GRID_MOD,    ONLY : GET_XMID, GET_YMID
      USE LOGICAL_MOD, ONLY : LEMEP

#     include "CMN_SIZE"    ! Size parameters

      ! Local variables
      INTEGER              :: AS, I, J, X, Y

      !=================================================================
      ! INIT_EMEP begins here!
      !=================================================================

      ! Return if LEMEP is false
      IF ( .not. LEMEP ) RETURN
      
      !--------------------------------
      ! Allocate and zero arrays
      !--------------------------------
      ALLOCATE( EMEP_NOx( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'EMEP_NOx' )
      EMEP_NOx = 0d0

      ALLOCATE( EMEP_CO( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'EMEP_CO' )
      EMEP_CO = 0d0

      ALLOCATE( EMEP_ALK4( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'EMEP_ALK4' )
      EMEP_ALK4 = 0d0

      ALLOCATE( EMEP_MEK( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'EMEP_MEK' )
      EMEP_MEK = 0d0

      ALLOCATE( EMEP_ALD2( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'EMEP_ALD2' )
      EMEP_ALD2 = 0d0

      ALLOCATE( EMEP_PRPE( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'EMEP_PRPE' )
      EMEP_PRPE = 0d0

      ALLOCATE( EMEP_C2H6( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'EMEP_C2H6' )
      EMEP_C2H6 = 0d0

      ALLOCATE( EUROPE_MASK( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'EUROPE_MASK' )
      EUROPE_MASK = 0d0

      !--------------------------------
      ! Make Europe mask, w/ corners
      ! (40E, 30N) and (45W, 74N)
      !--------------------------------

      ! Loop over latitudes
      DO J = 1, JJPAR
         
         ! Grid box lat [degrees]
         Y = GET_YMID( J )

         ! Loop over longitudes
         DO I = 1, IIPAR
            
            ! Grid box lon [degrees]
            X = GET_XMID( I )

            ! Set EUROPE_MASK=1 for boxes w/in the European region
            IF ( ( X >= -40d0 .and. X <= 45d0 )  .and. 
     &           ( Y >=  30d0 .and. Y <= 74d0 ) ) THEN
               EUROPE_MASK(I,J) = 1d0
            ENDIF
         ENDDO
      ENDDO

      ! Return to calling program
      END SUBROUTINE INIT_EMEP

!------------------------------------------------------------------------------

      SUBROUTINE CLEANUP_EMEP
!
!******************************************************************************
!  Subroutine CLEANUP_EMEP deallocates all module arrays 
!
!  NOTES:
!******************************************************************************
!
      !=================================================================
      ! CLEANUP_EMEP begins here!
      !=================================================================
      IF ( ALLOCATED( EMEP_NOx    ) ) DEALLOCATE( EMEP_NOx    )
      IF ( ALLOCATED( EMEP_CO     ) ) DEALLOCATE( EMEP_CO     )
      IF ( ALLOCATED( EMEP_ALK4   ) ) DEALLOCATE( EMEP_ALK4   )
      IF ( ALLOCATED( EMEP_MEK    ) ) DEALLOCATE( EMEP_MEK    )
      IF ( ALLOCATED( EMEP_ALD2   ) ) DEALLOCATE( EMEP_ALD2   )
      IF ( ALLOCATED( EMEP_PRPE   ) ) DEALLOCATE( EMEP_PRPE   )
      IF ( ALLOCATED( EMEP_C2H6   ) ) DEALLOCATE( EMEP_C2H6   )
      IF ( ALLOCATED( EUROPE_MASK ) ) DEALLOCATE( EUROPE_MASK )

      ! Return to calling program
      END SUBROUTINE CLEANUP_EMEP

!------------------------------------------------------------------------------

      ! End of module
      END MODULE EMEP_MOD