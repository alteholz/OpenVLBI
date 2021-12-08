/*  OpenVLBI - Open Source Very Long Baseline Interferometry
    Copyright © 2017-2019  Ilia Platone

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

#ifndef _VLBI_H
#define _VLBI_H

#ifdef  __cplusplus
extern "C" {
#endif

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <errno.h>
#include <unistd.h>
#include <string.h>
#include <math.h>
#include <float.h>
#include <sys/types.h>
#include <assert.h>
#include <pthread.h>
#include <dsp.h>

#ifndef DLL_EXPORT
#define DLL_EXPORT extern
#endif
/**
 * \mainpage
 *
@README@
 *
 *
 */

/**
 * \defgroup VLBI Very Long Baseline Interferometry
 * \authors Ilia Platone
 *
 * OpenVLBI is a free, open source set of applications for very long baseline radio interferometry.<br>
 */
/**@{*/

/**
 * \defgroup VLBI_Types VLBI types
*/
/**@{*/

typedef struct {
    double *GeographicLocation;
    double *Location;
    int Geo;
    dsp_stream_p Stream;
    char *Name;
    int Index;
} vlbi_node;

typedef struct {
    int relative;
    int locked;
    double *Target;
    double Ra;
    double Dec;
    double *baseline;
    double u, v, delay;
    double WaveLength;
    double SampleRate;
    vlbi_node Node1;
    vlbi_node Node2;
    char *Name;
    dsp_stream_p Stream;
} vlbi_baseline;
typedef double(* vlbi_func2_t)(double, double);
typedef void* vlbi_context;
typedef struct timespec timespec_t;
/**@}*/
/**
 * \defgroup VLBI_Defines VLBI defines
*/
/**@{*/
inline static double vlbi_default_delegate(double x, double y) {
    return x*y;
}
///if max() is not present you can use this one
#ifndef Min
#define Min(a,b) \
   ({ __typeof__ (a) _a = (a); \
       __typeof__ (b) _b = (b); \
     _a < _b ? _a : _b; })
#endif
///if max() is not present you can use this one
#ifndef Max
#define Max(a,b) \
   ({ __typeof__ (a) _a = (a); \
       __typeof__ (b) _b = (b); \
     _a > _b ? _a : _b; })
#endif
///Logarithm of a with arbitrary base b
#ifndef Log
#define Log(a,b) \
( log(a) / log(b) )
#endif

#define sin2cos(s) cos(asin(s))
#define cos2sin(c) sin(acos(c))

#define VLBI_VERSION_STRING "@VLBI_VERSION_STRING@"
#ifndef SPEED_MEAN
#define SPEED_MEAN LIGHTSPEED
#endif

#ifndef PI
#define PI (double)3.14159265358979323846
#endif
#ifndef ONE_SECOND_TICKS
#define ONE_SECOND_TICKS 100000000
#endif
#ifndef ONE_MILLISECOND_TICKS
#define ONE_MILLISECOND_TICKS 100000
#endif
#ifndef ONE_MICROSECOND_TICKS
#define ONE_MICROSECOND_TICKS 100
#endif
#ifndef SOLAR_DAY
#define SOLAR_DAY 86400
#endif
#ifndef SIDEREAL_DAY
#define SIDEREAL_DAY 86164.0905
#endif
#ifndef TRACKRATE_SIDEREAL
#define TRACKRATE_SIDEREAL ((360.0 * 3600.0) / SIDEREAL_DAY)
#endif
#ifndef TRACKRATE_SOLAR
#define TRACKRATE_SOLAR    ((360.0 * 3600.0) / SOLAR_DAY)
#endif
#ifndef TRACKRATE_LUNAR
#define TRACKRATE_LUNAR    14.511415
#endif
#ifndef EARTHRADIUSEQUATORIAL
#define EARTHRADIUSEQUATORIAL 6378137.0
#endif
#ifndef EARTHRADIUSPOLAR
#define EARTHRADIUSPOLAR 6356752.0
#endif
#ifndef EARTHRADIUSMEAN
#define EARTHRADIUSMEAN 6372797.0
#endif
#ifndef EULER
#define EULER 2.71828182845904523536028747135266249775724709369995
#endif
#ifndef ROOT2
#define ROOT2 1.41421356237309504880168872420969807856967187537694
#endif
#ifndef J2000
#define J2000 2451545.0
#endif
#ifndef GAMMAJ2000
#define GAMMAJ2000 (double)18.6971378528
#endif
#ifndef EULER
#define EULER (double)2.71828182845904523536028747135266249775724709369995
#endif
#ifndef ROOT2
#define ROOT2 (double)1.41421356237309504880168872420969807856967187537694
#endif
#ifndef AU
#define AU (double)1.495978707E+11
#endif
#ifndef PARSEC
#define PARSEC (double)(ASTRONOMICALUNIT*2.06264806247096E+5)
#endif
#ifndef AIRY
#define AIRY 1.21966
#endif
#ifndef CIRCLE_DEG
#define CIRCLE_DEG 360
#endif
#ifndef CIRCLE_AM
#define CIRCLE_AM (CIRCLE_DEG * 60)
#endif
#ifndef CIRCLE_AS
#define CIRCLE_AS (CIRCLE_AM * 60)
#endif
#ifndef RAD_AS
#define RAD_AS (CIRCLE_AS/(M_PI*2))
#endif
#ifndef ASTRONOMICALUNIT
#define ASTRONOMICALUNIT 1.495978707E+11
#endif
#ifndef PARSEC
#define PARSEC (ASTRONOMICALUNIT*2.06264806247096E+5)
#endif
#ifndef LIGHTSPEED
#define LIGHTSPEED 299792458.0
#endif
#ifndef LY
#define LY (LIGHTSPEED * SOLAR_DAY * 365)
#endif
extern unsigned long int MAX_THREADS;
inline unsigned long int vlbi_max_threads(unsigned long value) { if(value>0) { MAX_THREADS = value; DSP_MAX_THREADS = value; } return MAX_THREADS; }
/**@}*/
/**
 * \defgroup VLBI_Functions Essential VLBI functions
*/
/**@{*/

/**
* @brief Initialize a OpenVLBI instance.
* @return The OpenVLBI context
*/
DLL_EXPORT vlbi_context vlbi_init();

/**
* @brief Close a OpenVLBI instance.
* @param ctx The OpenVLBI context
*/
DLL_EXPORT void vlbi_exit(vlbi_context ctx);

/**
* @brief Add a stream into the current OpenVLBI context.
* @param ctx The OpenVLBI context
* @param Stream The OpenVLBI stream to add
* @param name A friendly name of this stream
*/
DLL_EXPORT void vlbi_add_node(vlbi_context ctx, dsp_stream_p Stream, char* name, int geographic_coordinates);

/**
* @brief Remove a stream from the current OpenVLBI context.
* @param ctx The OpenVLBI context
* @param name The friendly name of the stream to be removed
*/
DLL_EXPORT void vlbi_del_node(vlbi_context ctx, char* name);

/**
* @brief List all nodes of the current OpenVLBI context.
* @param ctx The OpenVLBI context
* @param nodes The nodes array pointer to be filled
* @return the number of nodes in the current context
*/
DLL_EXPORT int vlbi_get_nodes(void *ctx, vlbi_node** nodes);

/**
* @brief List all baselines of the current OpenVLBI context.
* @param ctx The OpenVLBI context
* @param baselines The baselines array pointer to be filled
* @return the number of baselines in the current context
*/
DLL_EXPORT int vlbi_get_baselines(void *ctx, vlbi_baseline** baselines);

/**
* @brief Add a model into the current OpenVLBI context.
* @param ctx The OpenVLBI context
* @param Stream The OpenVLBI stream to add
* @param name A friendly name of this model
*/
DLL_EXPORT void vlbi_add_model(vlbi_context ctx, dsp_stream_p Stream, char* name);

/**
* @brief Remove a model from the current OpenVLBI context.
* @param ctx The OpenVLBI context
* @param name The friendly name of the model to be removed
*/
DLL_EXPORT void vlbi_del_model(vlbi_context ctx, char* name);

/**
* @brief List all models of the current OpenVLBI context.
* @param ctx The OpenVLBI context
* @param model The model array pointer to be filled
* @return the number of models in the current context
*/
DLL_EXPORT int vlbi_get_models(void *ctx, dsp_stream_p** models);

/**
* @brief Set the location of the reference station.
* @param ctx The OpenVLBI context
* @param lat The latitude of the station
* @param lon The longitude of the station
* @param el The elevation of the station
*/
DLL_EXPORT void vlbi_set_location(void *ctx, double lat, double lon, double el);

/**
* @brief Set the buffer of a single baseline with already correlated data.
* @param ctx The OpenVLBI context
* @param node1 The name of the first node
* @param node2 The name of the second node
* @param buffer The buffer with correlated data
* @param len The length of the buffer
*/
DLL_EXPORT void vlbi_set_baseline_buffer(void *ctx, char* node1, char* node2, dsp_t *buffer, int len);

/**
* @brief Get the delays of a single baseline nodes.
* @param ctx The OpenVLBI context
* @param J2000Time The time of the calculation
* @param node1 The name of the first node
* @param node2 The name of the second node
* @param offset1 The output offset calculated for the first node
* @param offset2 The output offset calculated for the second node
*/
DLL_EXPORT void vlbi_get_offsets(vlbi_context ctx, double J2000Time, char* node1, char* node2, double Ra, double Dec, double *offset1, double *offset2);

/**
* @brief Plot a fourier transform of the object observed using celestial coordinates and the integration times given by the single streams.
* @param ctx The OpenVLBI context
* @param correlation_func The correlation delegate, you should use the vlbi_func2_t delegate function type for this argument.
* @param u The U size of the resulting UV plot
* @param v The V size of the resulting UV plot
* @param target The target position int Ra/Dec celestial coordinates
* @param freq The frequency observed. This parameter will scale the plot inverserly.
* @param sr The sampling rate. This parameter will be used as meter for the elements of the streams.
* @param nodelay 1 if no delay calculation should be done. streams entered are already synced.
* @param moving_baseline 1 if the location field of all streams is an array containing the coordinates of the nodes on each element of the data array.
* @param delegate The delegate function to be executed on each node stream buffer element.
* @return The OpenVLBI stream structure containing the Fourier transform of the object observed
*/
DLL_EXPORT dsp_stream_p vlbi_get_uv_plot(void *ctx, int u, int v, double *target, double freq, double sr, int nodelay, int moving_baseline, vlbi_func2_t delegate);

/**
* @brief Plot an inverse fourier transform of the uv plot buffer as magnitude, and its 4th order dft phase as its phase content.
* @param uv The Forier transform stream.
* @return dsp_stream_p The inverse fourier transform (an estimation of it)
*/
DLL_EXPORT dsp_stream_p vlbi_get_ifft_estimate(dsp_stream_p uv);

/**
* @brief Plot an inverse fourier transform of the uv plot using its current magnitude and phase components.
* @param uv The Forier transform stream.
* @return dsp_stream_p The inverse fourier transform
*/
DLL_EXPORT dsp_stream_p vlbi_get_ifft(dsp_stream_p uv);

/**
* @brief Apply the passed model as phase content of the uv plot.
* @param stream The Forier transform stream.
* @param model The phase model to apply.
* @return dsp_stream_p The fourier transform stream
*/
DLL_EXPORT dsp_stream_p vlbi_apply_phase_model(dsp_stream_p stream, dsp_stream_p model);

/**
* @brief Apply the passed model as magnitude content of the uv plot.
* @param stream The Forier transform stream.
* @param model The magnitude model to apply.
* @return dsp_stream_p The fourier transform stream
*/
DLL_EXPORT dsp_stream_p vlbi_apply_magnitude_model(dsp_stream_p stream, dsp_stream_p model);

/**
* @brief Mask the stream with the content of the mask stream, by multiplication of each element.
* @param stream The original stream.
* @param model The mask to apply.
* @return dsp_stream_p The stream masked
*/
DLL_EXPORT dsp_stream_p vlbi_apply_mask(dsp_stream_p stream, dsp_stream_p mask);

/**
* @brief Shift the stream by its dimensions.
* @param stream The shifted stream.
*/
DLL_EXPORT void vlbi_shift(dsp_stream_p stream);

/**
* @brief Print the version number of OpenVLBI.
* @return char* The Version string
*/
DLL_EXPORT char* vlbi_get_version();


/**@}*/
/**
 * \defgroup VLBI_Internal VLBI internal functions
*/
/**@{*/

/**
* @brief Return an aproximation of the timing offset that affects the vector passed as argument.
* @param stream1 The first stream.
* @param stream2 The second stream.
* @return int The calibration value.
*/
DLL_EXPORT int vlbi_calibrate(dsp_stream_p stream1, dsp_stream_p stream2);

/**
* @brief Return The baseline center in geographic coordinates.
* @param loc1 The first location.
* @param loc2 The second location.
* @return double* The center of the given coordinates
*/
DLL_EXPORT double* vlbi_calc_baseline_center(double *loc1, double *loc2);

/**
* @brief Return The 3d projection of the current observation.
* @param alt The altitude of the target.
* @param az The azimuth of the target.
* @param baseline The current baseline in meters.
* @param wavelength The wavelength observed.
* @return double* The 3d projection of the current observation.
*/
DLL_EXPORT double* vlbi_calc_3d_projection(double alt, double az, double *baseline);

/**
* @brief Return The UV coordinates of the current observation.
* @param proj The wavelength observed.
* @return double* The 2d coordinates of the current observation and the delay time as 3rd array element.
*/
DLL_EXPORT double* vlbi_calc_uv_coordinates(double *proj, double wavelength);

/**
* @brief Convert geographic location into xyz location
* @param loc The location of the observer.
* @return double* The xyz location.
*/
DLL_EXPORT double* vlbi_calc_location(double *loc);

/**
* @brief Convert radians into arcseconds
* @param rad Radians to convert into arcseconds.
* @return The arcseconds value corresponding to the given radians
*/
DLL_EXPORT double vlbi_rad2as(double rad);

/**
* @brief Convert arcseconds into radians
* @param as Arcseconds to convert into radians.
* @return double The radian value corresponding to the given arcseconds
*/
DLL_EXPORT double vlbi_as2rad(double as);

/**
* @brief Estimate Signal to noise ratio after a given integration time
* @param frequency Observed frequency.
* @return double The resolution at the baseline 0 (1m)
*/
DLL_EXPORT double vlbi_estimate_resolution_zero(double frequency);

/**
* @brief Estimate Signal to noise ratio after a given integration time
* @param resolution0 Resolution at baseline 0 (1m).
* @param baseline Current baseline.
* @return double The resolution at the given baseline
*/
DLL_EXPORT double vlbi_estimate_resolution(double resolution0, double baseline);

/**
* @brief obtain a timespec struct containing the date and time specified
* @param year the year.
* @param month the month.
* @param dom the day of the month.
* @param hour the hour.
* @param minute minutes.
* @param second seconds.
* @param nanosecond nanoseconds.
* @return the timespec struct containing the date and time specified.
*/
DLL_EXPORT timespec_t vlbi_time_mktimespec(int year, int month, int dom, int hour, int minute, int second, long nanosecond);

/**
* @brief Convert a timespec into J2000 time
* @param tp the timespec containing date and time informations.
* @return seconds since J2000.
*/
DLL_EXPORT double vlbi_time_timespec_to_J2000time(timespec_t tp);

/**
* @brief Obtain the local sidereal time at an arbitrary moment and location
* @param secs_since_J2000 seconds since J2000.
* @param Long the longitude.
*/
DLL_EXPORT double vlbi_time_J2000time_to_lst(double secs_since_J2000, double Long);
/**
* @brief obtain a timespec struct containing the date and time specified by a time string
* @param time String containing the time to be converted
* @return the timespec struct containing the date and time specified.
*/
DLL_EXPORT timespec_t vlbi_time_string_to_timespec(char* time);
/**
* @brief obtain a timespec struct containing the date and time specified by a J2000 time
* @param secs_since_J2000 seconds since J2000.
* @return the timespec struct containing the date and time specified.
*/
DLL_EXPORT timespec_t vlbi_time_J2000time_to_timespec(double secs_since_J2000);

/**
 * @brief get_local_hour_angle Returns local hour angle of an object
 * @param local_sideral_time Local Sideral Time
 * @param ra RA of object
 * @return Hour angle in hours (-12 to 12)
 */
DLL_EXPORT void vlbi_astro_alt_az_from_ra_dec(double J2000time, double Ra, double Dec, double Lat, double Long, double* Alt, double *Az);

/**
 * @brief get_local_hour_angle Returns local hour angle of an object
 * @param local_sideral_time Local Sideral Time
 * @param ra RA of object
 * @return Hour angle in hours (-12 to 12)
 */
DLL_EXPORT double vlbi_astro_get_local_hour_angle(double local_sideral_time, double ra);

/**
 * @brief get_alt_az_coordinates Returns alt-azimuth coordinates of an object
 * @param hour_angle Hour angle in hours (-12 to 12)
 * @param dec DEC of object
 * @param latitude latitude in INDI format (-90 to +90)
 * @param alt ALT of object will be returned here
 * @param az AZ of object will be returned here
 */
DLL_EXPORT void vlbi_astro_get_alt_az_coordinates(double hour_angle, double dec, double latitude, double* alt, double *az);

/**
 * @brief estimate_geocentric_elevation Returns an estimation of the actual geocentric elevation
 * @param latitude latitude in INDI format (-90 to +90)
 * @param sea_level_elevation sea level elevation
 * @return Aproximated geocentric elevation
 */
DLL_EXPORT double vlbi_astro_estimate_geocentric_elevation(double latitude, double sea_level_elevation);

/**
 * @brief estimate_field_rotation_rate Returns an estimation of the field rotation rate of the object
 * @param Alt altitude coordinate of the object
 * @param Az azimuth coordinate of the object
 * @param latitude latitude in INDI format (-90 to +90)
 * @return Aproximation of the field rotation rate
 */
DLL_EXPORT double vlbi_astro_estimate_field_rotation_rate(double Alt, double Az, double latitude);

/**
 * @brief estimate_field_rotation Returns an estimation of the field rotation rate of the object
 * @param hour_angle Hour angle in hours (-12 to 12)
 * @param field_rotation_rate the field rotation rate
 * @return Aproximation of the absolute field rotation
 */
DLL_EXPORT double vlbi_astro_estimate_field_rotation(double hour_angle, double field_rotation_rate);

/**
 * @brief parsec2m Convert parallax arcseconds into meters
 * @param parsec the parallax arcseconds to convert
 * @return Estimation of the distance in meters
 */
DLL_EXPORT double vlbi_astro_parsec2m(double parsec);

/**
 * @brief m2au Convert meters into astronomical units
 * @param m the distance in meters to convert
 * @return Estimation of the distance in astronomical units
 */
DLL_EXPORT double vlbi_astro_m2au(double m);

/**
 * @brief calc_delta_magnitude Returns the difference of magnitudes given two spectra
 * @param mag0 Reference magnitude
 * @param mag Relative magnitude to normalize
 * @param spectrum The spectrum of the star
 * @param spectrum_size The size of the spectrum
 * @param lambda the index of the position into the spectrum that parameter mag refers to
 * @return the magnitude difference
 */
DLL_EXPORT double vlbi_astro_calc_delta_magnitude(double mag0, double mag, double *spectrum, int spectrum_size, int lambda);

/**
 * @brief estimate_field_rotation Returns an estimation of the field rotation rate of the object
 * @param dist The distance in parallax radiuses
 * @param delta_mag The difference of magnitudes
 * @return Aproximation of the absolute magnitude in Δmag
 */
DLL_EXPORT double vlbi_astro_estimate_absolute_magnitude(double delta_dist, double delta_spectrum, double delta_mag);

/**
* \brief Read a FITS file and fill a dsp_stream_p with the contents
* \param src the input buffer
* \param red the location of the red pixel within the bayer pattern
* \param width the picture width
* \param height the picture height
* \return The new dsp_t array
*/
DLL_EXPORT dsp_stream_p vlbi_file_read_fits(void *data, size_t len);

DLL_EXPORT int vlbi_b64readfile(char* filename, void* buf);

/**@}*/
/**@}*/

#ifdef __cplusplus
}
#endif

#endif //_VLBI_H

