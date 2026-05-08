enum PeriodeFilter { hariIni, mingguIni, bulanIni }

extension PeriodeFilterLabel on PeriodeFilter {
  String get label {
    switch (this) {
      case PeriodeFilter.hariIni:
        return 'Hari ini';
      case PeriodeFilter.mingguIni:
        return 'Minggu ini';
      case PeriodeFilter.bulanIni:
        return 'Bulan ini';
    }
  }
}
