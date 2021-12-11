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
 * \defgroup VLBI Very Long Baseline Interferometry API
 *
 * OpenVLBI is a free, open source library for very long baseline interferometry.<br>
 * OpenVLBI provides functions to locate, aim, cross-correlate and synchronize more nodes, or observatories together.
 * Each observation creates a Fourier plane filled with the perpective projection of each baseline during the various captures.
 * The nodes can contain a location companion for each sample for moving baseline projection, or a single location.
 * Projection is calculated by an aperture synthesis algorithm.
 * OpenVLBI saves each observation into an internal models list, where you can load your own models also.
 * There are various model operations, including differential Fourier transform, inverse Fourier transform, shift, and masking.
 * More operations can be done on models by using the DSP API, included into OpenVLBI.
 * Once your work is done, the models can also be saved as jpeg, png, or fits picture files.
 *
 * \author Ilia Platone
 */

 ///
/**@{*/

/**
 * \defgroup VLBI_Types VLBI types
*/
/**@{*/

///A single node, returned by vlbi_get_nodes into an array
typedef struct {
///Geographic coordinates array (latitude, longitude, elevation)
    double *GeographicLocation;
///Current location array in meters
    double *Location;
///Whether this node uses geographic coordinates
    int Geo;
///Node's DSP stream
    dsp_stream_p Stream;
///Node's name
    char *Name;
///Node's index - oldest zero
    int Index;
} vlbi_node;

///A single baseline, returned by vlbi_get_baselines into an array
typedef struct {
///Whether this baseline's nodes use coordinates relative to the context reference station
    int relative;
///Whether this baseline's nodes use coordinates relative to the context reference station
    int locked;
///The baseline's current celestial target array
    double *Target;
///The baseline's current celestial target right ascension
    double Ra;
///The baseline's current celestial target declination
    double Dec;
///The baseline's 3d sizes in meters
    double *baseline;
///Current u perspective location in pixels
    double u;
///Current v perspective location in pixels
    double v;
///Current delay in seconds
    double delay;
///Wavelength observed in meters
    double WaveLength;
///Samples per second
    double SampleRate;
///Earlier node
    vlbi_node Node1;
///Latter node
    vlbi_node Node2;
///Baseline's name
    char *Name;
///Baseline's DSP stream
    dsp_stream_p Stream;
} vlbi_baseline;

/**
* @brief The delegate function type to pass to vlbi_plot_uv_plane
*
* This function type natively accepts the double type, but you must consider to cast these arguments
* as other types, like structure, unions, C++ classes or other kind of object pointers.
*
* @param farest baseline's node current value
* @param closest baseline's node current value
* @return the result of the operation done
*/
typedef double(* vlbi_func2_t)(double, double);

///the OpenVLBI context object type
typedef void* vlbi_context;

///Definition of the timespec_t in a C type, just for convenience
typedef struct timespec timespec_t;
/**@}*/
/**
 * \defgroup VLBI_Defines VLBI defines
*/
/**@{*/
///A placeholder delegate that simply multiplies the values received from vlbi_get_uv_plot
inline static double vlbi_default_delegate(double x, double y) {
    return x*y;
}
#ifndef Min
///if max() is not present you can use this one
#define Min(a,b) \
   ({ __typeof__ (a) _a = (a); \
       __typeof__ (b) _b = (b); \
     _a < _b ? _a : _b; })
#endif
#ifndef Max
///if max() is not present you can use this one
#define Max(a,b) \
   ({ __typeof__ (a) _a = (a); \
       __typeof__ (b) _b = (b); \
     _a > _b ? _a : _b; })
#endif
#ifndef Log
///Logarithm of a with arbitrary base
#define Log(a,b) \
( log(a) / log(b) )
#endif

///Get the cosine of a sine value
#define sin2cos(s) cos(asin(s))

///Get the sine from a cosine value
#define cos2sin(c) sin(acos(c))

///The current OpenVLBI version
#define VLBI_VERSION_STRING "@VLBI_VERSION_STRING@"

#ifndef CIRCLE_DEG
///degrees in a circle
#define CIRCLE_DEG 360.0
#endif
#ifndef CIRCLE_AM
///arcminutes in a circle
#define CIRCLE_AM (CIRCLE_DEG * 60.0)
#endif
#ifndef CIRCLE_AS
///arcseconds in a circle
#define CIRCLE_AS (CIRCLE_AM * 60.0)
#endif
#ifndef RAD_AS
///arcseconds per radian
#define RAD_AS (CIRCLE_AS/(M_PI*2.0))
#endif
#ifndef ONE_SECOND_TICKS
///Many architectures reach 100 ns clock resolutions
#define ONE_SECOND_TICKS 100000000
#endif
#ifndef ONE_MILLISECOND_TICKS
///Our millisecond tick value
#define ONE_MILLISECOND_TICKS 100000
#endif
#ifndef ONE_MICROSECOND_TICKS
///Our microsecond tick value
#define ONE_MICROSECOND_TICKS 100
#endif
#ifndef SOLAR_DAY
///Solar day duration in seconds
#define SOLAR_DAY 86400
#endif
#ifndef SIDEREAL_DAY
///Sidereal day aproximated duration in seconds
#define SIDEREAL_DAY 86164.0905
#endif
#ifndef TRACKRATE_SIDEREAL
///Sidereal track rate in arcseconds/second
#define TRACKRATE_SIDEREAL (CIRCLE_AS / SIDEREAL_DAY)
#endif
#ifndef TRACKRATE_SOLAR
///Solar track rate in arcseconds/second
#define TRACKRATE_SOLAR (CIRCLE_AS / SOLAR_DAY)
#endif
#ifndef TRACKRATE_LUNAR
///Lunar track rate in arcseconds/second
#define TRACKRATE_LUNAR 14.511415
#endif
#ifndef EARTHRADIUSEQUATORIAL
///Earth equatorial radius aproximation in meters
#define EARTHRADIUSEQUATORIAL 6378137.0
#endif
#ifndef EARTHRADIUSPOLAR
///Earth polar radius aproximation in meters
#define EARTHRADIUSPOLAR 6356752.0
#endif
#ifndef EARTHRADIUSMEAN
///Earth mean radius aproximation in meters
#define EARTHRADIUSMEAN 6372797.0
#endif
#ifndef EULER
///Our Euler constant
#define EULER 2.71828182845904523536028747135266249775724709369995
#endif
#ifndef ROOT2
///Our square root of 2 constant
#define ROOT2 1.41421356237309504880168872420969807856967187537694
#endif
#ifndef PI
///Our PI constant
#define PI 3.14159265358979323846
#endif
///Our c constant
#ifndef LIGHTSPEED
#define LIGHTSPEED 299792458.0
#endif
#ifndef J2000
///J2000 epoch in seconds
#define J2000 2451545.0
#endif
#ifndef GAMMAJ2000
///Right ascension of the meridian at J2000 zero at Greenwich
#define GAMMAJ2000 18.6971378528
#endif
#ifndef AIRY
#define AIRY 1.21966
#endif
#ifndef ASTRONOMICALUNIT
///Aproximation of an astronomical unit in meters
#define ASTRONOMICALUNIT 1.495978707E+11
#endif
#ifndef PARSEC
///Aproximation of a parsec in meters
#define PARSEC (ASTRONOMICALUNIT/sin(PI*2.0/CIRCLE_AS))
#endif
#ifndef LY
///Aproximation of a light year in meters
#define LY (LIGHTSPEED * SIDEREAL_DAY * 365.0)
#endif
#ifndef SPEED_MEAN
///We use the speed of light as means speed reference
#define SPEED_MEAN LIGHTSPEED
#endif
///The maximum number of threads allowed
extern unsigned long int MAX_THREADS;
/**@}*/
/**
 * \defgroup VLBI_Functions Essential VLBI functions
*/
/**@{*/

/**
* @brief Initialize a OpenVLBI instance.
* @return The OpenVLBI context
*/
DLL_EXPORT vlbi_context vlbi_init(void);

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
* @param geographic_coordinates Whether to use geographic coordinates
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
* @param models The model array pointer to be filled
* @return the number of models in the current context
*/
DLL_EXPORT int vlbi_get_models(void *ctx, dsp_stream_p** models);

/**
* @brief Get a single model from the current OpenVLBI context.
* @param ctx The OpenVLBI context
* @param name The name of the chosen model
* @return the model chosen as dsp_stream_p
*/
DLL_EXPORT dsp_stream_p vlbi_get_model(void *ctx, char* name);

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
* @param Ra The right ascension coordinate
* @param Dec The declination coordinate
* @param offset1 The output offset calculated for the first node
* @param offset2 The output offset calculated for the second node
*/
DLL_EXPORT void vlbi_get_offsets(vlbi_context ctx, double J2000Time, char* node1, char* node2, double Ra, double Dec, double *offset1, double *offset2);

/**
* @brief Plot a fourier transform of the object observed using celestial coordinates and the integration times given by the single streams into a new model with the given name.
* @param ctx The OpenVLBI context
* @param name The name of the new model
* @param u The U size of the resulting UV plot
* @param v The V size of the resulting UV plot
* @param target The target position int Ra/Dec celestial coordinates
* @param freq The frequency observed. This parameter will scale the plot inverserly.
* @param sr The sampling rate. This parameter will be used as meter for the elements of the streams.
* @param nodelay 1 if no delay calculation should be done. streams entered are already synced.
* @param moving_baseline 1 if the location field of all streams is an array containing the coordinates of the nodes on each element of the data array.
* @param delegate The delegate function to be executed on each node stream buffer element.
*/
DLL_EXPORT void vlbi_get_uv_plot(void *ctx, char *name, int u, int v, double *target, double freq, double sr, int nodelay, int moving_baseline, vlbi_func2_t delegate);

/**
* @brief Plot an inverse fourier transform of the uv plot using its current magnitude and phase components.
* @param ctx The OpenVLBI context
* @param name The name of the newly created model.
* @param magnitude The magnitude model.
* @param phase The phase model.
*/
DLL_EXPORT void vlbi_get_ifft(vlbi_context ctx, char *name, char *magnitude, char *phase);

/**
* @brief Get the fourier transform of the given model and save its magnitude and phase components into two new models named so.
* @param ctx The OpenVLBI context
* @param model The name of the model from which extract the magnitude and phase.
* @param magnitude The name of the model where to save the magnitude.
* @param phase The name of the model where to save the phase.
*/
DLL_EXPORT void vlbi_get_fft(vlbi_context ctx, char *model, char *magnitude, char *phase);

/**
* @brief Mask the stream with the content of the mask stream, by multiplication of each element.
* @param ctx The OpenVLBI context
* @param name The name of the newly created model.
* @param model The name of the model containing the data to be masked.
* @param mask The name of the model containing the mask.
*/
DLL_EXPORT void vlbi_apply_mask(vlbi_context ctx, char* name, char* model, char* mask);

/**
* @brief Shift a model by its dimensions.
* @param ctx The OpenVLBI context
* @param name The name of the model to be shifted.
*/
DLL_EXPORT void vlbi_shift(vlbi_context ctx, char* name);

/**
* @brief Add a model from a png file.
* @param ctx The OpenVLBI context
* @param filename The file name of the picture to read
* @param name The name of the newly created model.
*/
DLL_EXPORT void vlbi_add_model_from_png(void *ctx, char *filename, char* name);

/**
* @brief Add a model from a jpeg file.
* @param ctx The OpenVLBI context
* @param filename The file name of the picture to read
* @param name The name of the newly created model.
*/
DLL_EXPORT void vlbi_add_model_from_jpeg(void *ctx, char *filename, char* name);

/**
* @brief Add a model from a fits file.
* @param ctx The OpenVLBI context
* @param filename The file name of the picture to read
* @param name The name of the newly created model.
*/
DLL_EXPORT void vlbi_add_model_from_fits(void *ctx, char *filename, char* name);

/**
* @brief Write a model to a png file.
* @param ctx The OpenVLBI context
* @param filename The file name of the picture to write
* @param name The name of the model chosen.
*/
DLL_EXPORT void vlbi_get_model_to_png(void *ctx, char *filename, char* name);

/**
* @brief Write a model to a jpeg file.
* @param ctx The OpenVLBI context
* @param filename The file name of the picture to write
* @param name The name of the model chosen.
*/
DLL_EXPORT void vlbi_get_model_to_jpeg(void *ctx, char *filename, char* name);

/**
* @brief Write a model to a fits file.
* @param ctx The OpenVLBI context
* @param filename The file name of the picture to write
* @param name The name of the model chosen.
*/
DLL_EXPORT void vlbi_get_model_to_fits(void *ctx, char *filename, char* name);

/**
* @brief Add a node from a fits file stored into a memory buffer.
* @param ctx The OpenVLBI context
* @param filename The filename of the fits to read
* @param name The name of the newly created model
* @param geo whether to consider the file coordinates as geographic or relative to the context station
*/
DLL_EXPORT void vlbi_add_node_from_fits(void *ctx, char *filename, char* name, int geo);

/**
* @brief get/set the maximum number of threads allowed
* @param value if greater than 1, set a maximum number of threads allowed
* @return The current or new number of threads allowed during runtime
*/
inline unsigned long int vlbi_max_threads(unsigned long value) { if(value>0) { MAX_THREADS = value; DSP_MAX_THREADS = value; } return MAX_THREADS; }

/**
* @brief Print the current version of OpenVLBI.
* @return char* The Version string
*/
DLL_EXPORT char* vlbi_get_version(void);


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
* @return double* The 3d projection of the current observation.
*/
DLL_EXPORT double* vlbi_calc_3d_projection(double alt, double az, double *baseline);

/**
* @brief Return The UV coordinates of the current observation.
* @param proj The 2d projection of the current baseline perspective distance.
* @param wavelength The wavelength observed.
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
* @brief Obtain a timespec struct containing the date and time specified
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
* @brief Obtain a timespec struct containing the date and time specified by a time string
* @param time String containing the time to be converted
* @return the timespec struct containing the date and time specified.
*/
DLL_EXPORT timespec_t vlbi_time_string_to_timespec(char* time);
/**
* @brief Obtain a timespec struct containing the date and time specified by a J2000 time
* @param secs_since_J2000 seconds since J2000.
* @return the timespec struct containing the date and time specified.
*/
DLL_EXPORT timespec_t vlbi_time_J2000time_to_timespec(double secs_since_J2000);

/**
 * @brief Obtain the altitude and azimuth coordinate of a celestial coordinate at a specific time
 * @param J2000time Current time offset in seconds from J2000
 * @param Ra Right ascension coordinate of the object
 * @param Dec Declination coordinate of object
 * @param Lat Latitude of the observatory
 * @param Long Longitude of the observatory
 * @param Alt Altitude pointer
 * @param Az Azimuth pointer
 */
DLL_EXPORT void vlbi_astro_alt_az_from_ra_dec(double J2000time, double Ra, double Dec, double Lat, double Long, double* Alt, double *Az);

/**
 * @brief Returns local hour angle of an object
 * @param local_sideral_time Local Sideral Time
 * @param ra RA of object
 * @return Hour angle in hours (-12 to 12)
 */
DLL_EXPORT double vlbi_astro_get_local_hour_angle(double local_sideral_time, double ra);

/**
 * @brief Returns alt-azimuth coordinates of an object
 * @param hour_angle Hour angle in hours (-12 to 12)
 * @param dec DEC of object
 * @param latitude latitude in INDI format (-90 to +90)
 * @param alt ALT of object will be returned here
 * @param az AZ of object will be returned here
 */
DLL_EXPORT void vlbi_astro_get_alt_az_coordinates(double hour_angle, double dec, double latitude, double* alt, double *az);

/**
 * @brief Returns an estimation of the actual geocentric elevation
 * @param latitude latitude in INDI format (-90 to +90)
 * @param sea_level_elevation sea level elevation
 * @return Aproximated geocentric elevation
 */
DLL_EXPORT double vlbi_astro_estimate_geocentric_elevation(double latitude, double sea_level_elevation);

/**
 * @brief Returns an estimation of the field rotation rate of the object
 * @param Alt altitude coordinate of the object
 * @param Az azimuth coordinate of the object
 * @param latitude latitude in INDI format (-90 to +90)
 * @return Aproximation of the field rotation rate
 */
DLL_EXPORT double vlbi_astro_estimate_field_rotation_rate(double Alt, double Az, double latitude);

/**
 * @brief Returns an estimation of the field rotation rate of the object
 * @param hour_angle Hour angle in hours (-12 to 12)
 * @param field_rotation_rate the field rotation rate
 * @return Aproximation of the absolute field rotation
 */
DLL_EXPORT double vlbi_astro_estimate_field_rotation(double hour_angle, double field_rotation_rate);

/**
 * @brief Convert parallax arcseconds into meters
 * @param parsec the parallax arcseconds to convert
 * @return Estimation of the distance in meters
 */
DLL_EXPORT double vlbi_astro_parsec2m(double parsec);

/**
 * @brief Convert meters into astronomical units
 * @param m the distance in meters to convert
 * @return Estimation of the distance in astronomical units
 */
DLL_EXPORT double vlbi_astro_m2au(double m);

/**
 * @brief Returns the difference of magnitudes given two spectra
 * @param mag0 Reference magnitude
 * @param mag Relative magnitude to normalize
 * @param spectrum The spectrum of the star
 * @param spectrum_size The size of the spectrum
 * @param lambda the index of the position into the spectrum that parameter mag refers to
 * @return the magnitude difference
 */
DLL_EXPORT double vlbi_astro_calc_delta_magnitude(double mag0, double mag, double *spectrum, int spectrum_size, int lambda);

/**
 * @brief Returns an estimation of the field rotation rate of the object
 * @param delta_dist The distance difference between the two references
 * @param delta_spectrum The difference of magnitudes
 * @param delta_mag The difference of magnitudes
 * @return Aproximation of the absolute magnitude in Δmag
 */
DLL_EXPORT double vlbi_astro_estimate_absolute_magnitude(double delta_dist, double delta_spectrum, double delta_mag);

/**
 * @brief Returns a stream filled with all the elements needed to form a vlbi node, by loading a FITS file containing them
 * @param filename The FITS filename
 * @return The new stream to add as node
 */
DLL_EXPORT dsp_stream_p vlbi_file_read_fits(char *filename);

/**@}*/
/**@}*/

#ifdef __cplusplus
}
#endif

#endif //_VLBI_H

