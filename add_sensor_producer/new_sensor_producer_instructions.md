# Instructions for Adding New Sensor/Producer to Pmesdr
## Steps 1-6 Have Already Been Done for AMSR3
### 1. In _pmesdr/src/prod/gsx/src/_
#### Open `gsx.h`:
   1. Near the other `gsx_<sensor>_channel_name[]` declarations, add a new `static const char * array` for your sensor:

```js
static const char *gsx_NEW_SENSOR_channel_name[] = {
      /* example channels */
      "brightness_temperature_11H", 
      "brightness_temperature_11V",
      "brightness_temperature_36H",
      ...
}
```

### 2. In _pmesdr/include/_
#### Open `cetb.h`:
   1. Add values for new sensor name, platform, NSIDC dataset, etc. Most of these will be easy to recognize once the new sensor data are examined, e.g. there are enums defined for the platform, producer id, etc.
   2. **IMPORTANT:** Some functions map to enums so the order matters. For example: The order of the `cetb_platform_to_sensor[]` array corresponds exactly to the order of the platform IDs defined in the satellite platform IDs enum. So If you're adding a new platform (e.g., `CETB_NEW_SATELLITE`), you must:
      - Add it to the end of the satellite platform IDs enum. Add the corresponding sensor ID to the end of `cetb_platform_to_sensor[]` (e.g., `CETB_NEW_SENSOR`).
   3. If new_sensor has unique channels, define a new enum, channel list and Map input beam/channel index to `NEW_SENSOR` channel ID. Example:

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
#### Open `gsx.c`:
   1. Modify module to handle any new values added for the new sensor/producer.
   2. What will probably need modifications:
   - `get_gsx_global_variables` that sets the number of channels for a possibly new sensor
   - `assign_channels` that verifies that the input channel name matches the expected channels from `cetb.h`.
   3. This may require more changes, depending on how similar a new sensor is to the existing sensors.

### 4. In _pmesdr/src/prod/meas_meta_make/_
#### Open `meas_meta_make.c`:
   1. **IMPORTANT:** Only need this step if you've added a new satellite platform to `CETB_platform` enum (in step 2), else skip to `meas_meta_setup.c` step.
   2. Find below section of code:

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

   3. Choose a unique identifier for the new satellite platform (in this example, 'N') then add:
      - `if ( CETB_NEW_SATELLITE == F_num ) sen = 'N';`
      - **IMPORTANT:** `CETB_NEW_SATELLITE` should match what you added to CETB_platform enum

#### Open `meas_meta_setup.c`:
   1. Around line _870_, assign the `gsx_count` based on the new channel mapping in `cetb.h`.

**Example:**
```c
else if ( CETB_AMSR3 == gsx->short_sensor )
		gsx_count = cetb_ibeam_to_cetb_amsr3_channel[ibeam];
```

   2. Around line _2330_, add new sensor to the function `box_size_by_channel`.

**Example:**
```c
else if ( CETB_AMSR3 == id ) {
    switch ( cetb_ibeam_to_cetb_amsr3_channel[ibeam] ) {
      case AMSR3_06H:
      case AMSR3_06V:
        *box_size = 20;
        break;
      case AMSR3_10H:
      case AMSR3_10V:
        *box_size = 20;
        break;
      ...
```

   3. **IMPORTANT:** Only need next parts if 89GHz channel is split into A and B beams.
   - Around line _560_, add your platform:

**Example:**
```c
} else if ( CETB_GOSATGW == cetb_platform )  {
   combine_setup_files( outpath, &save_area, 1 , (int *)cetb_ibeam_to_cetb_amsr3_channel,
               (int)AMSR3_89AH, (int)AMSR3_89BH);
   combine_setup_files( outpath, &save_area, 1 , (int *)cetb_ibeam_to_cetb_amsr3_channel,
               (int)AMSR3_89AV, (int)AMSR3_89BV);
}
```

   - Around line _1240_, call combine_setup_files again with mode 2 to finalize the merging of the 89GHz A/B files. 
   
**Example:**
```c
if ( CETB_GOSATGW == cetb_platform ) {
   combine_setup_files( outpath, &save_area, 2 , (int *)cetb_ibeam_to_cetb_amsr3_channel,
     (int)AMSR3_89AH, (int)AMSR3_89BH);
   combine_setup_files( outpath, &save_area, 2 , (int *)cetb_ibeam_to_cetb_amsr3_channel,
     (int)AMSR3_89AV, (int)AMSR3_89BV);
}
   ```

### 5. In _pmesdr/ipython_notebooks/_
**IMPORTANT:** Only need this step if you've added a new NSIDC dataset to `CETB_NSIDC_dataset` enum (in step 2), else skip to step 6.

#### Open `Create CETB file template.ipynb`:
   1. Create a new cetb output file template. Do this by running the below code in a new cell.
      -  **IMPORTANT:** authID should match what you added to `cetb_NSIDC_dataset_id[]`
   2. This creates the template file that corresponds to your new NSIDC dataset ID. Output for this example would be `cetb_file/templates/NSIDC9999_template.nc`

```py
authID = "NSIDC9999" # change to your authID
product_version = 1 # change to your chosen product_version
fid = initTemplate(authID, product_version)
fid = addProjectionMetadata( fid )
fid.close()
```

### 6. In _pmesdr/src/prod/cetb_file/src/_
#### Open `cetb_file.c`:
   1. In the function `cetb_template_filename`, add new if clause with your new sensor, your chosen provider and your NSIDC dataset:
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
}
```
## Steps 7-9 are Specific to your **Environment**
### 7. In your python lib _site-packages/gsx/_
#### Open `cli.py`:
   1. Add new sensor to `SOURCE_TYPES`

### 8. In your python lib _site-packages/gsx/strategies_
#### Create Transformer Strategy file for new sensor:
   - Transformer stragegy file for AMSR3 can be found at _/add_sensor_producer/amsr3.py_
#### Open `__init__.py`:
   1. Add new source type import.

**Example:**
```py
from .amsr3 import AMSR3_TS # noqa
```

#### Open `transformer_strategy.py`:
   1. Add new sensor to `_short_sensor(self, sensor)` function.
   2. Add new platform to `_short_platform(self, platform)` function.

### 9. In your python lib _site-packages/gsx/ancillary/_
#### Create cdl.template file for new sensor:
   - Template file for AMSR3 can be found at _/add_sensor_producer/gsx_amsr3.cdl.template_