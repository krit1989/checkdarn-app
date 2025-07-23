enum FilterMode {
  smart, // อัจฉริยะ: รัศมีจากแผนที่ + จังหวัดเดียวกันถ้านอกรัศมี
  radius, // รัศมีจากแผนที่เท่านั้น
  province, // จังหวัดเดียวกันเท่านั้น
}

extension FilterModeExtension on FilterMode {
  String get label {
    switch (this) {
      case FilterMode.smart:
        return 'อัจฉริยะ (รัศมี + จังหวัด)';
      case FilterMode.radius:
        return 'รัศมีเท่านั้น';
      case FilterMode.province:
        return 'จังหวัดเดียวกัน';
    }
  }

  String get description {
    switch (this) {
      case FilterMode.smart:
        return 'แสดงโพสต์ในรัศมีที่กำหนด หากไม่มีจะแสดงในจังหวัดเดียวกัน';
      case FilterMode.radius:
        return 'แสดงเฉพาะโพสต์ในรัศมีที่กำหนดจากแผนที่';
      case FilterMode.province:
        return 'แสดงโพสต์ในจังหวัดเดียวกันเท่านั้น';
    }
  }

  String get emoji {
    switch (this) {
      case FilterMode.smart:
        return '🧠';
      case FilterMode.radius:
        return '📍';
      case FilterMode.province:
        return '🏙️';
    }
  }
}
