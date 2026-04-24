import datetime as dt
import numpy as np
import re

from . import amsr_l1c_qc
import gsx
import gsx.spherical_geometry as spherical_geometry
import gsx.utility as u
from .transformer_strategy import TransformerStrategy


class AMSR3_TS(TransformerStrategy):
    """Transformer Strategy to convert JAXA AMSR3 data

    """

    # --------------------------
    # Class attributes
    # --------------------------

    tb_fcdr_prefix = 'AMSR3'
    cdl_template = 'gsx_amsr3.cdl.template'
    input_provider = 'JAXA'
    input_type = 'AMSR3'

    source_epoch = 'seconds since 1993-01-01T00:00:00.00Z'

    # --------------------------
    # Instance methods
    # --------------------------

    def __init__(self, *args, **kwargs):
        TransformerStrategy.__init__(self, *args, **kwargs)
        #        self._metadata_xml_ = None

    def dimension_values(self):
        overlap_scans = int(self._get_globalattrs('NumberOfScansOverlap', 0))
        nscans = self._get_dimensions("NumberOfScans")

        return {
            'scans_loc1': nscans + 2 * overlap_scans,
            'scans_loc2': nscans + 2 * overlap_scans,
            'scans_loc3': nscans + 2 * overlap_scans,

            'measurements_loc1': self._get_dimensions("NumberOfPixelsPerScan"),
            'measurements_loc2': self._get_dimensions("NumberOfPixelsPerScan89"),
            'measurements_loc3': self._get_dimensions("NumberOfPixelsPerScan89"),
        }

    def _transfer_orbit(self, gsx_dataset):
        satorbit = self._orbit()
        u.valid_set_variable(gsx_dataset, 'orbit', satorbit, self.orbit_bounds)

    def _assign_field_of_view(self, gsx_dataset):
        # Note the units for these are kilometers and the sizes are from Imaoka et al. 2010
        field_of_view_definitions = [
            {'frequency': '6.9', 'polarizations': ['V', 'H'], 'dimensions': (61, 35)},
            {'frequency': '10.7', 'polarizations': ['V', 'H'], 'dimensions': (42, 24)},
            {'frequency': '18', 'polarizations': ['V', 'H'], 'dimensions': (22, 14)},
            {'frequency': '23', 'polarizations': ['V', 'H'], 'dimensions': (26, 15)},
            {'frequency': '37', 'polarizations': ['V', 'H'], 'dimensions': (12, 7)},
            {'frequency': '89A', 'polarizations': ['V', 'H'], 'dimensions': (5, 3)},
            {'frequency': '89B', 'polarizations': ['V', 'H'], 'dimensions': (5, 3)}
        ]
        for fov in field_of_view_definitions:
            for p in fov['polarizations']:
                variable_name = 'efov_{0}{1}'.format(fov['frequency'], p)
                u.set_variable(gsx_dataset, variable_name, fov['dimensions'])

    def _get_dimensions(self, name):
        if name == "NumberOfPixelsPerScan":
            return (243)
        if name == "NumberOfPixelsPerScan89":
            return (486)
        else:
            return (False)

    def _get_globalattrs(self, attribute_element, default=None):
        ds = self.source_dataset

        if attribute_element in ds.ncattrs():
            return ds.getncattr(attribute_element)

        return default

    def _orbit(self):
        return int(self._get_globalattrs('OrbitNumberStart'))

    def _quality_threshold(self):
        thresholds = {
            'low': 255,
            'medium': 99,
            'high': 0
        }
        return thresholds.get(self.quality, thresholds['high'])

    def _source_dataset_empty(self):  # function returns true if the dataset is empty
        missing_scans = int(self._get_globalattrs('NumberOfMissingScans'))
        nscans = int(self._get_globalattrs('NumberOfScans'))
        return (missing_scans == nscans)

    def _scan_times(self, year, month, day):
        dts = []
        utc_data = self.source_dataset.variables['ScanTimeUTC']
        G_year   = utc_data[:, 0].astype(int)
        G_month  = utc_data[:, 1].astype(int)
        G_day    = utc_data[:, 2].astype(int)
        G_hour   = utc_data[:, 3].astype(int)
        G_minute = utc_data[:, 4].astype(int)
        G_second = utc_data[:, 5].astype(int)
        G_milli  = utc_data[:, 6].astype(int)
        for i in np.arange(len(G_year)):
            dts.append((dt.datetime(G_year[i], G_month[i], G_day[i], G_hour[i], G_minute[i],
                                    G_second[i], 1000*G_milli[i]) -
                        dt.datetime(year, month, day, 0, 0, 0)).total_seconds())
        return dts

    def _transfer_attributes(self, gsx_dataset):
        u.set_attribute(gsx_dataset, 'gsx_date_created',
                        str(dt.datetime.today()))

        u.set_attribute(gsx_dataset, 'gsx_version',
                        gsx.VERSION)

        u.set_attribute(gsx_dataset, 'input_provider',
                        self.input_provider)

        idea = self._get_globalattrs('GranuleID')
        u.set_attribute(gsx_dataset, 'gsx_source', idea)

        time_end = self._get_globalattrs('ObservationEndDateTime')
        u.set_attribute(gsx_dataset, 'time_coverage_end', time_end)

        time_start = self._get_globalattrs('ObservationStartDateTime')
        u.set_attribute(gsx_dataset, 'time_coverage_start', time_start)

        overlap_scans = int(self._get_globalattrs('NumberOfScansOverlap'))
        u.set_attribute(gsx_dataset, 'overlapscans', overlap_scans)

        splatform = self._get_globalattrs('PlatformShortName').replace('-', '')
        if (splatform):
            u.set_attribute(gsx_dataset, 'short_platform', splatform)
        else:
            return (False)
        u.set_attribute(gsx_dataset, 'platform',
                        '%s > Greenhouse gas Observing Satellite' %
                        (splatform))

        ssensor = self._get_globalattrs('SensorShortName')
        if (ssensor):
            u.set_attribute(gsx_dataset, 'short_sensor', ssensor)
        else:
            return (False)
        u.set_attribute(gsx_dataset, 'sensor',
                        '%s > Advanced Microwave Scanning Radiometer 3' % (ssensor))

    def _transfer_brightness_temperatures(self, gsx_dataset):
        if self._source_dataset_empty():
            return

        tb_duos = [
            ('Brightness Temperature (6.9GHz,V)', 'brightness_temperature_6.9V'),
            ('Brightness Temperature (6.9GHz,H)', 'brightness_temperature_6.9H'),
            ('Brightness Temperature (10.7GHz,V)', 'brightness_temperature_10.7V'),
            ('Brightness Temperature (10.7GHz,H)', 'brightness_temperature_10.7H'),
            ('Brightness Temperature (18.7GHz,V)', 'brightness_temperature_18V'),
            ('Brightness Temperature (18.7GHz,H)', 'brightness_temperature_18H'),
            ('Brightness Temperature (23.8GHz,V)', 'brightness_temperature_23V'),
            ('Brightness Temperature (23.8GHz,H)', 'brightness_temperature_23H'),
            ('Brightness Temperature (36.5GHz,V)', 'brightness_temperature_37V'),
            ('Brightness Temperature (36.5GHz,H)', 'brightness_temperature_37H'),
            ('Brightness Temperature (89.0GHz-A,V)', 'brightness_temperature_89AV'),
            ('Brightness Temperature (89.0GHz-A,H)', 'brightness_temperature_89AH'),
            ('Brightness Temperature (89.0GHz-B,V)', 'brightness_temperature_89BV'),
            ('Brightness Temperature (89.0GHz-B,H)', 'brightness_temperature_89BH')]

        for tb, target in tb_duos:
            data = np.array(self.source_dataset[tb])
            u.valid_set_variable(gsx_dataset, target, data, self.tb_bounds)

    def _transfer_earth_azimuth_angles(self, gsx_dataset):
        if self._source_dataset_empty():
            return

        # ------------- loc1: 06 -------------
        eaa_loc1 = np.array(self.source_dataset["EarthAzimuth_P06"])
        u.valid_set_variable(gsx_dataset, "earth_azimuth_angle_loc1", eaa_loc1, self.eaa_bounds,
            {"source": "EarthAzimuth_P06"})

        # ------------- loc2: 89A -------------
        eaa_loc2 = np.array(self.source_dataset["EarthAzimuth_P89A"])
        u.valid_set_variable( gsx_dataset, "earth_azimuth_angle_loc2", eaa_loc2, self.eaa_bounds,
            {"source": "EarthAzimuth_P89A"})

        # ------------- loc3: 89B -------------
        eaa_loc3 = np.array(self.source_dataset["EarthAzimuth_P89B"])
        u.valid_set_variable(gsx_dataset, "earth_azimuth_angle_loc3", eaa_loc3, self.eaa_bounds,
            {"source": "EarthAzimuth_P89B"})

    def _transfer_earth_incidence_angles(self, gsx_dataset):
        if self._source_dataset_empty():
            return

        # ------------- loc1: 06 -------------
        eia_loc1 = np.array(self.source_dataset["EarthIncidence_P06"])
        u.valid_set_variable(gsx_dataset, "earth_incidence_angle_loc1", eia_loc1, self.eia_bounds)

        # ------------- loc2: 89A -------------
        eia_loc2 = np.array(self.source_dataset["EarthIncidence_P89A"])
        u.valid_set_variable(gsx_dataset, "earth_incidence_angle_loc2", eia_loc2, self.eia_bounds)

        # ------------- loc3: 89B -------------
        eia_loc3 = np.array(self.source_dataset["EarthIncidence_P89B"])
        u.valid_set_variable(gsx_dataset,"earth_incidence_angle_loc3", eia_loc3, self.eia_bounds)

    def _transfer_measurement_positions(self, gsx_dataset):
        if self._source_dataset_empty():
            return

        # ------------- loc1: 06 -------------
        lat_loc1 = np.array(self.source_dataset["Latitude of Observation Point for 6"])
        lon_loc1 = np.array(self.source_dataset["Longitude of Observation Point for 6"])

        u.valid_set_variable(gsx_dataset, "latitude_loc1", lat_loc1, self.lat_bounds)
        u.valid_set_variable(gsx_dataset, "longitude_loc1", lon_loc1, self.lon_bounds)

        # ------------- loc2: 89A -------------
        lat_loc2 = np.array(self.source_dataset["Latitude of Observation Point for 89A"])
        lon_loc2 = np.array(self.source_dataset["Longitude of Observation Point for 89A"])

        u.valid_set_variable(gsx_dataset, "latitude_loc2", lat_loc2, self.lat_bounds)
        u.valid_set_variable(gsx_dataset, "longitude_loc2", lon_loc2, self.lon_bounds)

        # ------------- loc3: 89B -------------
        lat_loc3 = np.array(self.source_dataset["Latitude of Observation Point for 89B"])
        lon_loc3 = np.array(self.source_dataset["Longitude of Observation Point for 89B"])

        u.valid_set_variable(gsx_dataset, "latitude_loc3", lat_loc3, self.lat_bounds)
        u.valid_set_variable(gsx_dataset, "longitude_loc3", lon_loc3, self.lon_bounds)

    def _transfer_scan_times(self, gsx_dataset):
        if self._source_dataset_empty():
            return

        gsx_epoch = u.get_variable(gsx_dataset, 'scan_time_loc1').units
        p = re.compile(r"(.*)(\d{4})(-)(\d{2})(-)(\d{2})(.*)")
        m = p.match(gsx_epoch)
        year, month, day = (m.groups(0)[1], m.groups(0)[3], m.groups(0)[5])
        yeari = int(year)
        monthi = int(month)
        dayi = int(day)
        new_times = self._scan_times(yeari, monthi, dayi)
        u.set_variable(gsx_dataset, 'scan_time_loc1', new_times)
        u.set_variable(gsx_dataset, "scan_time_loc2", new_times)
        u.set_variable(gsx_dataset, "scan_time_loc3", new_times)

    def _transfer_spacecraft_positions(self, gsx_dataset):
        if self._source_dataset_empty():
            return

        latitudes = np.nanmean(self.source_dataset["Latitude_P06"])
        longitudes = np.nanmean(self.source_dataset["Longitude_P06"])

        u.valid_set_variable(gsx_dataset, "spacecraft_latitude_loc1", latitudes, self.lat_bounds)
        u.valid_set_variable(gsx_dataset, "spacecraft_longitude_loc1", longitudes, self.lon_bounds)

        u.valid_set_variable(gsx_dataset,"spacecraft_latitude_loc2", latitudes, self.lat_bounds)
        u.valid_set_variable(gsx_dataset, "spacecraft_longitude_loc2", longitudes, self.lon_bounds)

        u.valid_set_variable(gsx_dataset, "spacecraft_latitude_loc3", latitudes, self.lat_bounds)
        u.valid_set_variable(gsx_dataset, "spacecraft_longitude_loc3", longitudes, self.lon_bounds)