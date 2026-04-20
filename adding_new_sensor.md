# Adding New Sensor to Pmesdr

### 1. In _pmesdr/src/prod/gsx/src/_
   1. Open `gsx.h`
   2.  To add a new sensor called `NEW_SENSOR` with the following made-up channel:
   - "brightness_temperature_11H",
   - "brightness_temperature_11V",
   - "brightness_temperature_36H"
   3. Near the other `gsx_<sensor>_channel_name[]` declarations, add a new `static const char * arra`y for your sensor:

```js
static const char *gsx_NEW_SENSOR_channel_name[] = {
      "brightness_temperature_11H",
      "brightness_temperature_11V",
      "brightness_temperature_36H"
}
```

### 2. In _pmesdr/include/_
   1. Open `cetb.h`
   2. Add values for new sensor name, platform, NSIDC dataset, etc. Most of these will be easy to recognize once the new sensor data are examined, e.g. there are enums defined for the platform, producer id, etc.
   3. **IMPORTANT:** Some functions map to enums so the order matters. For example: The order of the `cetb_platform_to_sensor[]` array corresponds exactly to the order of the platform IDs defined in the satellite platform IDs enum. So If you're adding a new platform (e.g., `CETB_NEW_SATELLITE`), you must:
      - Add it to the end of the satellite platform IDs enum. Add the corresponding sensor ID to the end of `cetb_platform_to_sensor[]` (e.g., `CETB_NEW_SENSOR`).
   4. If new_sensor has unique channels, define a new enum, channel list and Map input beam/channel index to `NEW_SENSOR` channel ID. Example:

```js
/*
* NEW_SENSOR channel IDs
*/
typedef enum {
	NEW_SENSOR_NO_CHANNEL = -1,
	NEW_SENSOR_11H,
	NEW_SENSOR_11V,
	NEW_SENSOR_36H,
	NEW_SENSOR_NUM_CHANNELS
} cetb_new_sensor_channel_id

/*
* NEW_SENSOR channel ID names
*/
static const char *cetb_new_sensor_channel_name[] = {
       "11H",
       "11V",
       "36H"
}

static const cetb_new_sensor_channel_id cetb_ibeam_to_cetb_new_sensor_channel[] = {
       NEW_SENSOR_NO_CHANNEL,
       NEW_SENSOR_11H,
       NEW_SENSOR_11V,
       NEW_SENSOR_36H
}
```

### 3. In _pmesdr/src/prod/gsx/src/_
   1. Open `gsx.c`
   2. Modify module to handle any new values added for the new sensor/producer.
   3. What will probably need modifications:
   - `get_gsx_global_variables` that sets the number of channels for a possibly new sensor
   - `assign_channels` that verifies that the input channel name matches the expected channels from `cetb.h`.
   4. This may require more changes, depending on how similar a new sensor is to the existing sensors.

### 4. In _pmesdr/src/prod/meas_meta_make/_
   1. **IMPORTANT:** Only need this step if you've added a new satellite platform to `CETB_platform` enum (in step 2), else skip to step 5.
   2. Open `meas_meta_make.c`
   3. Fine below section of code:
   4. Choose a unique identifier for the new satellite platform (in this example, 'N') then add:
      - `if ( CETB_NEW_SATELLITE == F_num ) sen = 'N';`
      - **IMPORTANT:** `CETB_NEW_SATELLITE` should match what you added to CETB_platform enum

```js
/* code for the correct names from cetb.h */
if ( CETB_NIMBUS7 == F_num ) sen='R';
if ( CETB_AQUA == F_num ) sen='A';
if ( CETB_F08 <= F_num && F_num <= CETB_F15 ) sen='F';
if ( CETB_F16 <= F_num && F_num <= CETB_F19 ) sen='I';
if ( CETB_SMAP == F_num ) sen='S';
if ( CETB_GCOMW1 == F_num ) sen = 'G';
/* F=ssmi, A=AMSRE/AQUA, R=SMMR, I=SSMIS, S=SMAP, G=GCOMW1/AMSR2 */
```

### 5. In _pmesdr/ipython_notebooks/_
   1. **IMPORTANT:** Only need this step if you've added a new NSIDC dataset to `CETB_NSIDC_dataset` enum (in step 2), else skip to step 6.
   2. Open Create CETB file `template.ipynb`
   3. Create a new cetb output file template. Do this by running the below code in a new cell.
      -  **IMPORTANT:** authID should match what you added to `cetb_NSIDC_dataset_id[]`
   4. This creates the template file that corresponds to your new NSIDC dataset ID. Output for this example would be `cetb_file/templates/NSIDC9999_template.nc`

```py
authID = "NSIDC9999" # change to your authID
product_version = 1 # change to your chosen product_version
fid = initTemplate(authID, product_version)
fid = addProjectionMetadata( fid )
fid.close()
```

### 6. In _pmesdr/src/prod/cetb_file/src/_
   1. Open `cetb_file.c`
   2. In the function `cetb_template_filename`, add new if clause with your new sensor, your chosen provider and your NSIDC dataset:
      - **IMPORTANT:** Make sure this block is added before the final strcat() that builds the filename path.

```js
if ( CETB_NEW_SENSOR == sensor_id ) {
if ( CETB_MY_PROVIDER == producer_id ) {
   *cetb_dataset_id_index = CETB_NSIDC_9999;
} else {
  fprintf( stderr, "%s: Invalid sensor_id=%d producer_id=%d combination\n",
  __FUNCTION__, sensor_id, producer_id );
  return NULL;
  }
}]
```

In ./envs/pmesdrEnv/lib/python3.1/site-packages/gsx/cli.py
   add new source to SOURCE_TYPES

In miniconda3/envs/pmesdrEnv/lib/python3.12/site-packages/gsx/strategies
   In __init__.py, add new source type import 
from .amsr3 import AMSR3_TS # noqa

In /miniconda3/envs/pmesdrEnv/lib/python3.1/site-packages/gsx/strategies/transformer_strategy.py