// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscriber.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubscriberAdapter extends TypeAdapter<Subscriber> {
  @override
  final int typeId = 0;

  @override
  Subscriber read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Subscriber(
      name: fields[0] as String,
      endDate: fields[1] as DateTime,
      amount: fields[2] as double,
      status: fields[3] as String,
      notes: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Subscriber obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.endDate)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
