package Driver
// https://mapr.com/ebooks/spark/08-recommendation-engine-spark.html
// convert an RDD to a DataFrame.
import sqlContext.implicits._
import org.apache.spark.sql._
import org.apache.spark.mllib.recommendation.{ALS, MatrixFactorizationModel, Rating}

object Driver {
  def main(args: Array[String]): Unit = {
    // SQLContext for structured data
    val sqlContext = new org.apache.spark.sql.SQLContext(sc)

    // load the data into a RDD
    val ratingText = sc.textFile("/home/jovyan/work/datasets/spark-ebook/ratings.dat")
    val ratingsRDD = ratingText.map(parseRating).cache()

    println("Total number of ratings: " + ratingsRDD.count())
    println("Total number of movies rated: " + ratingsRDD.map(_.product).distinct().count())
    println("Total number of users who rated movies: " + ratingsRDD.map(_.user).distinct().count())

    // load the data into DataFrames
    val usersDF = sc.textFile("/home/jovyan/work/datasets/spark-ebook/users.dat").map(parseUser).toDF()
    val moviesDF = sc.textFile("/home/jovyan/work/datasets/spark-ebook/movies.dat").map(parseMovie).toDF()

    // create a DataFrame from the ratingsRDD
    val ratingsDF = ratingsRDD.toDF()

    // register the DataFrames as a temp table
    ratingsDF.registerTempTable("ratings")
    moviesDF.registerTempTable("movies")
    usersDF.registerTempTable("users")

    // print the schema
    usersDF.printSchema()
    moviesDF.printSchema()
    ratingsDF.printSchema()

    // Get the max, min ratings along with the count of users who have rated a movie.
    val results = sqlContext.sql(
      """select movies.title, movierates.maxr, movierates.minr, movierates.cntu
          from(SELECT ratings.product, max(ratings.rating) as maxr,
          min(ratings.rating) as minr,count(distinct user) as cntu
          FROM ratings group by ratings.product ) movierates
          join movies on movierates.product=movies.movieId
          order by movierates.cntu desc""")
    // DataFrame show() displays the top 20 rows in  tabular form
    results.show()

    // Show the top 10 most-active users and how many times they rated a movie
    val mostActiveUsersSchemaRDD = sqlContext.sql(
      """SELECT ratings.user, count(*) as ct from ratings
          group by ratings.user order by ct desc limit 10""")
    println(mostActiveUsersSchemaRDD.collect().mkString("\n"))

    // Find the movies that user 4169 rated higher than 4
    val results = sqlContext.sql(
      """SELECT ratings.user, ratings.product,
          ratings.rating, movies.title FROM ratings JOIN movies
          ON movies.movieId=ratings.product
          where ratings.user=4169 and ratings.rating > 4""")
    results.show()

    ////////// ALS
    // Randomly split ratings RDD into training data RDD (80%) and test data RDD (20%)
    val splits = ratingsRDD.randomSplit(Array(0.8, 0.2), 0L)
    val trainingRatingsRDD = splits(0).cache()
    val testRatingsRDD = splits(1).cache()
    val numTraining = trainingRatingsRDD.count()
    val numTest = testRatingsRDD.count()
    println(s"Training: $numTraining, test: $numTest.")

    // build a ALS user product matrix model with rank=20, iterations=10
    val model = new ALS().setRank(20).setIterations(10).run(trainingRatingsRDD)

    // Get the top 4 movie predictions for user 4169
    val topRecsForUser = model.recommendProducts(4169, 5)

    // get movie titles to show with recommendations
    val movieTitles=moviesDF.map(array => (array(0), array(1))).collectAsMap()

    // print out top recommendations for user 4169 with titles
    topRecsForUser.map(rating => (movieTitles(rating.product), rating.rating)).foreach(println)

  }
}
