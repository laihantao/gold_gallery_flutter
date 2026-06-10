// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gold_price.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GoldPriceAdapter extends TypeAdapter<GoldPrice> {
  @override
  final int typeId = 10;

  @override
  GoldPrice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GoldPrice(
      shopName: fields[0] as String,
      price916: fields[1] as double?,
      price999: fields[2] as double?,
      fetchedAt: fields[3] as DateTime?,
      websiteDate: fields[4] as String?,
      logoAsset: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, GoldPrice obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.shopName)
      ..writeByte(1)
      ..write(obj.price916)
      ..writeByte(2)
      ..write(obj.price999)
      ..writeByte(3)
      ..write(obj.fetchedAt)
      ..writeByte(4)
      ..write(obj.websiteDate)
      ..writeByte(5)
      ..write(obj.logoAsset);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoldPriceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
