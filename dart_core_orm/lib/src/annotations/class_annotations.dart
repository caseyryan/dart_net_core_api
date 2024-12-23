class ClassAnnotation {
  const ClassAnnotation();
}

/// can be used on a class if the table name should
/// be different from the class name -> plural -> to lowercase
class TableName extends ClassAnnotation {
  final String name;

  const TableName(this.name);
}
