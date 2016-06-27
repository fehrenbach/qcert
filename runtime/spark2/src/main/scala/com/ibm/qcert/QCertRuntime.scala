/*
 * Copyright 2015-2016 IBM Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.qcert

import java.util
import java.util.Comparator

import org.apache.spark.sql.Row
import org.apache.spark.sql.catalyst.expressions.GenericRowWithSchema
import org.apache.spark.sql.types._

import scala.reflect.ClassTag

abstract class QCertRuntime {
  // TODO revisit naming -- we don't want to clash with spark.sql.functions._ functions

  def customerType() =
    StructType(
      StructField("age", IntegerType)::
      StructField("cid", IntegerType)::
      StructField("name", StringType)::Nil)

  def purchaseType() =
    StructType(
      StructField("cid", IntegerType)::
      StructField("name", StringType)::
      StructField("pid", IntegerType)::
      StructField("quantity", IntegerType)::Nil)

  def mainEntityType() =
    StructType(
      StructField("doubleAttribute", DoubleType)::
      StructField("id", IntegerType)::
      StructField("stringId", StringType)::Nil)

  val CONST$WORLD_07 = Array(
    brand(srow(customerType(), 32, 123, "John Doe"), "entities.Customer"),
    brand(srow(customerType(), 32, 124, "Jane Doe"), "entities.Customer"),
    brand(srow(customerType(), 34, 125, "Jim Does"), "entities.Customer"),
    brand(srow(customerType(), 32, 126, "Jill Does"), "entities.Customer"),
    brand(srow(customerType(), 34, 127, "Joan Doe"), "entities.Customer"),
    brand(srow(customerType(), 35, 128, "James Do"), "entities.Customer"),

    brand(srow(purchaseType(), 123, "Tomatoe", 1, 3), "entities.Purchase"),
    brand(srow(purchaseType(), 123, "Potatoe", 2, 1), "entities.Purchase"),
    brand(srow(purchaseType(), 125, "Stiletto", 3, 64), "entities.Purchase"),
    brand(srow(purchaseType(), 126, "Libretto", 4, 62), "entities.Purchase"),
    brand(srow(purchaseType(), 128, "Dough", 5, 4), "entities.Purchase"),
    brand(srow(purchaseType(), 128, "Croissant", 6, 2), "entities.Purchase"),

    brand(srow(mainEntityType(), 4, 201, "201"), "entities.MainEntity"),
    brand(srow(mainEntityType(), 100, 202, "202"), "entities.MainEntity"))


  val CONST$WORLD = CONST$WORLD_07

  /* Data
   * ====
   *
   * Int, Double, String, Boolean
   * Records are Rows with schema with fields in lexicographic order.
   * Bags are arrays, unordered. TODO change this!
   * Either and Branded values are encoded as Rows.
   */

  /* Records
 * =======
 *
 * We represent records as Rows with a schema of StructType.
 * Rows are glorified tuples. We can access fields by name, but most operations are by position only.
 * Fields must be ordered by field name!
 */
  type Record = Row

  /** More convenient record (row with schema) construction.
    * Splice array into varargs call: let a = Array(1, 2); srow(schema, a:_*) */
  private def srow(s: StructType, vals: Any*): Row = {
    assert(s.fields.length == vals.length,
      "Number of record fields does not match the schema. Did you forget to splice an array parameter?")
    assert(s.fieldNames.sorted.distinct.sameElements(s.fieldNames),
      "Field names must be unique and sorted!")
    new GenericRowWithSchema(vals.toArray, s)
  }

  // TODO this is a mess
  def recordConcat(l: Record, r: Record): Record = {
    val rightFieldNames = r.schema.fieldNames diff l.schema.fieldNames
    val rightFieldNamesSet = rightFieldNames.toSet
    val allFieldNames = (rightFieldNames ++ l.schema.fieldNames).distinct.sorted
    val schema = allFieldNames.foldLeft(new StructType())((schema: StructType, field: String) => {
      val inLeft = l.schema.fieldNames.indexOf(field)
      schema.add(if (inLeft == -1) r.schema.fields(r.schema.fieldNames.indexOf(field)) else l.schema.fields(inLeft))
    })
    // val schema: StructType = rightFieldNames.foldLeft(l.schema)((schema: StructType, rfn: String) =>
    //  schema.add(r.schema.fields(r.fieldIndex(rfn))))
    val names = l.schema.fieldNames ++ rightFieldNames
    val values = l.toSeq ++ rightFieldNames.map((rfn: String) => r.get(r.fieldIndex(rfn)))
    val sortedValues = (names zip values).sortBy(_._1).map(_._2)
    srow(schema, sortedValues: _*)
  }

  // Ugh. To do stuff with the result, we have to pass T to dot.
  // Alternatively, we can return Object, or Any, or something and write runtime functions that cast their arguments to whatever they need first.
  def dot[T](n: String)(l: Record): T = l.getAs[T](n)

  def mergeConcat(l: Record, r: Record): Array[Record] = {
    val concatenated = recordConcat(l, r)
    val duplicates = l.schema.fieldNames intersect r.schema.fieldNames
    // TODO could do this before...
    for (field <- duplicates)
      if (!equal(r.get(r.fieldIndex(field)), concatenated.get(concatenated.fieldIndex(field))))
        return Array()
    Array(concatenated)
  }

  /** UnaryOp ARec */
  def singletonRecord(n: String, v: Int): Record = {
    srow(StructType(StructField(n, IntegerType, false) :: Nil), v)
  }

  def singletonRecord(n: String, v: Record): Record = {
    srow(StructType(StructField(n, v.schema, false) :: Nil), v)
  }

  // TODO Ugh, this hacky inference business works for primitives and even records, but not Arrays
  //  def singltonRecord[T](n: String, v: Array[T]): Record = {
  //    srow(StructType(StructField(n, ArrayType(T), false)::Nil), v)
  //  }

  /* Either
 * ======
 *
 * Encode either as a record with left and right fields. Unlike in the Java/JS harness,
 * we need both fields to be actually present, because Rows are really indexed by position.
 * If we had only one field named left or right, we could not make a collection of eithers.
 */
  // Could we use Scala's either through a user-defined datatype or something?
  type Either = Row

  def eitherStructType(l: DataType, r: DataType): StructType =
    StructType(StructField("left", l, true) :: StructField("right", r, true) :: Nil)

  // Not sure we can abuse dispatch like this to "infer" the schema. Seems to work...
  def left(v: Int): Either =
    srow(eitherStructType(IntegerType, DataTypes.NullType), v, null)

  def left(v: Row): Either =
    srow(eitherStructType(v.schema, DataTypes.NullType), v, null)

  def right(v: Row): Either =
    srow(eitherStructType(DataTypes.NullType, v.schema), null, v)

  // In general, there is no way to infer the types S and R.
  // We need to put annotations on the parameters of left and right during codegen.
  def either[S, T, R](v: Either, left: (S) => T, right: (R) => T): T =
    if (v.isNullAt(1 /* right! */)) left(v.getAs[S]("left"))
    else right(v.getAs[R]("right"))

  /* Brands
 * ======
 *
 * We represent a branded value as a row with two fields: data and type.
 * TODO What happens if we brand a branded value?
 */

  type Brand = String
  type BrandedValue = Row

  def brandStructType(t: DataType): StructType =
    StructType(StructField("data", t, false)
      :: StructField("type", ArrayType(StringType, false), false) :: Nil)

  // Same thing as with either, need to infer/pass the Spark type. Can we factor this out?
  def brand(v: Int, b: Brand*): BrandedValue =
    srow(brandStructType(IntegerType), v, b)

  def brand(v: Row, b: Brand*): BrandedValue =
    srow(brandStructType(v.schema), v, b)

  def unbrand[T](bv: BrandedValue): T =
    bv.getAs[T]("data")

  // TODO
  def isSubBrand(a: Brand, b: Brand) =
    false

  def cast(v: BrandedValue, bs: Brand*): Either = {
    // Why is this special cased for a singleton list? Don't we have to do that for subtyping too?
    if (bs == Seq("Any"))
      left(v)
    else if (bs.forall((brand: Brand) => {
      v.getAs[Seq[Brand]]("type").exists((typ: Brand) => {
        typ == brand || isSubBrand(typ, brand)
      })
    }))
      left(v)
    else
      right(null)
  }

  /* Bags
   * ====
   *
   */
  // type Bag[T] = Array[T] // Huh, with Bag alias overloading does not work.

  def arithMean(b: Array[Int]): Double =
    if (b.length == 0) 0.0
    // Cast, because it's 1960 and we don't know how to do arithmetic properly, so our default / is integer division.
    else b.sum.asInstanceOf[Double] / b.length

  def arithMean(b: Array[Double]): Double =
    if (b.length == 0) 0.0
    else b.sum / b.length

  /*
  def distinct[T](b: Array[T])(implicit m: ClassTag[T]): Array[T] = {
    val set = new util.TreeSet(new QCertComparator[T]())
    val a = util.Arrays.asList(b: _*)
    for (x <- b)
      set.add(x)
    val res = new Array[T](set.size())
    var i = 0
    for (x <- scala.collection.JavaConversions.asScalaIterator(set.iterator())) {
      res(i) = x
      i += 1
    }
    res
  }*/

  /* Sorting & equality
 * ==================
 */
  object QCertOrdering extends Ordering[Any] {
    def compare(x: Any, y: Any): Int = (x, y) match {
      // NULL sorts before anything else
      case (null, null) => 0
      case (null, _) => -1
      case (_, null) => 1
      // Boolean, false sorts before true
      case (false, false) => 0
      case (false, true) => -1
      case (true, false) => 1
      case (true, true) => 0
      // Other primitive types
      case (x: Int, y: Int) => x compareTo y
      case (x: Double, y: Double) => x compareTo y
      case (x: String, y: String) => x compareTo y
      // Bags
      case (a: Array[_], b: Array[_]) =>
        // Shorter arrays sort before longer arrays
        if (a.length.compareTo(b.length) != 0)
          return a.length.compareTo(b.length)
        // Sort elements
        val lt = compare(_: Any, _: Any) < 0
        val l = List(a: _*).sortWith(lt)
        val r = List(b: _*).sortWith(lt)
        // The first unequal element between the two arrays determines array sort order
        for ((le, re) <- l zip r) {
          if (le < re)
            return -1
          if (le > re)
            return 1
        }
        0
      // Records
      case (a: Row, b: Row) =>
        // This assumes fields are in lexicographic order (by field name)!
        for ((le, re) <- a.toSeq zip b.toSeq) {
          if (le < re)
            return -1
          if (le > re)
            return 1
        }
        0
    }
  }

  class QCertComparator[T] extends Comparator[T] {
    def compare(a: T, b: T): Int = QCertOrdering.compare(a, b)
  }

  def equal(a: Any, b: Any) =
    QCertOrdering.compare(a, b) == 0
}