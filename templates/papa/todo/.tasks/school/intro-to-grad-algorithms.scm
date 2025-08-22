(use-modules (scripts lib class))

(define todo
  (list
    (class/render-assignment
      "Lecture: DP2: Knapsack - Chain Multiply"
      "https://edstem.org/us/courses/82037/lessons/145029/slides/834938"
      "August 25 - August 31, 2025")
    (class/render-assignment
      "Quiz 1: Format Quiz on DP"
      "https://gatech.instructure.com/courses/468386"
      "8/25 - 8/31, 2025")
    (class/render-assignment
      "Lecture: DC1: Fast Integer Multiplication"
      "https://edstem.org/us/courses/82037/lessons/145031/slides/835003"
      "September 1 - September 7, 2025")
    (class/render-assignment
      "Lecture: DC3: Solving Recurrences"
      "https://edstem.org/us/courses/82037/lessons/145033/slides/835035"
      "September 1 - September 7, 2025")
    (class/render-assignment
      "Homework 2"
      "https://gatech.instructure.com/courses/468386"
      "September 1 - September 7, 2025")
    (class/render-assignment
      "Quiz 2: Format Quiz on D&C"
      "https://gatech.instructure.com/courses/468386"
      "September 1 - September 7, 2025")
    (class/render-assignment
      "Mock Exam 1"
      "https://gatech.instructure.com/courses/468386"
      "September 1 - September 7, 2025")
    (class/render-assignment
      "Lecture: DC2: Linear-Time Median"
      "https://edstem.org/us/courses/82037/lessons/145032/slides/835018"
      "9/8 - 9/14, 2025")
    (class/render-assignment
      "Homework 3"
      "https://gatech.instructure.com/courses/468386"
      "9/8 - 9/14, 2025")
    (class/render-assignment
      "Quiz 3: Content Quiz on DP + D&C"
      "https://gatech.instructure.com/courses/468386"
      "September 1 - September 7, 2025")
    (class/render-assignment
      "Homework 4"
      "https://gatech.instructure.com/courses/468386"
      "9/15 - 9/21, 2025")
    (class/render-assignment
      "Exam 1"
      "https://gatech.instructure.com/courses/468386"
      "9/18 - 9/21, 2025")
    (class/render-assignment
      "Lecture: DP3: Shortest Paths"
      "https://edstem.org/us/courses/82037/lessons/145030/slides/834971"
      "9/22 - 9/28, 2025")
    (class/render-assignment
      "Lecture: GR1: Strongly Connected Components"
      "https://edstem.org/us/courses/82037/lessons/145036/slides/835091"
      "9/29 - 10/5, 2025")
    (class/render-assignment
      "Lecture: GR2: 2-Satisfiability"
      "https://edstem.org/us/courses/82037/lessons/145037/slides/835121"
      "9/29 - 10/5, 2025")
    (class/render-assignment
      "Homework 5"
      "https://gatech.instructure.com/courses/468386"
      "9/29 - 10/5, 2025")
    (class/render-assignment
      "Quiz 4: Format Quiz on Graph Theory"
      "https://gatech.instructure.com/courses/468386"
      "9/29 - 10/5, 2025")
    (class/render-assignment
      "Lecture: GR3: Minimum Spanning Tree"
      "https://edstem.org/us/courses/82037/lessons/145038/slides/835137"
      "10/6 - 10/12 , 2025")
    (class/render-assignment
      "Homework 6"
      "https://gatech.instructure.com/courses/468386"
      "10/6 - 10/12, 2025")
    (class/render-assignment
      "Quiz 5: Content Quiz on Graph Theory"
      "https://gatech.instructure.com/courses/468386"
      "10/6 - 10/12, 2025")
    (class/render-assignment
      "Lecture: MF1: Ford-Fulkerson Algorithm"
      "https://edstem.org/us/courses/82037/lessons/145040/slides/835182"
      "10/13 - 10/19, 2025")
    (class/render-assignment
      "Lecture: MF2: Max-Flow Min-Cut"
      "https://edstem.org/us/courses/82037/lessons/145041/slides/835202"
      "10/13 - 10/19, 2025")
    (class/render-assignment
      "Lecture: MF3: Image Segmentation"
      "https://edstem.org/us/courses/82037/lessons/145042/slides/835218"
      "10/13 - 10/19, 2025")
    (class/render-assignment
      "Lecture: MF4: Edmonds-Karp Algorithm"
      "https://edstem.org/us/courses/82037/lessons/145043/slides/835233"
      "10/13 - 10/19, 2025")
    (class/render-assignment
      "Homework 7"
      "https://gatech.instructure.com/courses/468386"
      "10/13 - 10/19, 2025")
    (class/render-assignment
      "Homework 8"
      "https://gatech.instructure.com/courses/468386"
      "10/13 - 10/19, 2025")
    (class/render-assignment
      "Exam 2"
      "https://gatech.instructure.com/courses/468386"
      "10/23 - 10/26, 2025")
    (class/render-assignment
      "Lecture: NP1: Definitions"
      "https://edstem.org/us/courses/82037/lessons/145045/slides/835266"
      "10/27 - 11/2, 2025")
    (class/render-assignment
      "Lecture: NP2: 3SAT"
      "https://edstem.org/us/courses/82037/lessons/145046/slides/835301"
      "10/27 - 11/2, 2025")
    (class/render-assignment
      "Lecture: NP3: Graph Problems"
      "https://edstem.org/us/courses/82037/lessons/145047/slides/835320"
      "10/27 - 11/2, 2025")
    (class/render-assignment
      "Homework 9"
      "https://gatech.instructure.com/courses/468386"
      "10/27 - 11/2, 2025")
    (class/render-assignment
      "Quiz 6: Format Quiz on NP Theory"
      "https://gatech.instructure.com/courses/468386"
      "10/27 - 11/2, 2025")
      (class/render-assignment
      "Lecture: LP1: Linear Programming"
      "https://edstem.org/us/courses/82037/lessons/145050/slides/835375"
      "11/3 - 11/9, 2025")
    (class/render-assignment
      "Lecture: LP2: Geometry"
      "https://edstem.org/us/courses/82037/lessons/145051/slides/835398"
      "11/3 - 11/9, 2025")
    (class/render-assignment
      "Lecture: LP3: Duality"
      "https://edstem.org/us/courses/82037/lessons/145052/slides/835406"
      "11/3 - 11/9, 2025")
    (class/render-assignment
      "Homework 10"
      "https://gatech.instructure.com/courses/468386"
      "11/3 - 11/9, 2025")
    (class/render-assignment
      "Quiz 7: Content Quiz on NP & LP"
      "https://gatech.instructure.com/courses/468386"
      "11/3 - 11/9, 2025")
    (class/render-assignment
      "Lecture: NP4: Knapsack"
      "https://edstem.org/us/courses/82037/lessons/145048/slides/835351"
      "11/10 - 11/16, 2025")
    (class/render-assignment
      "Lecture: NP5: Halting Problem"
      "https://edstem.org/us/courses/82037/lessons/145049/slides/835367"
      "11/10 - 11/16, 2025")
    (class/render-assignment
      "Lecture: LP4: Max-SAT Approximation"
      "https://edstem.org/us/courses/82037/lessons/145053/slides/835425"
      "11/10 - 11/16, 2025")
    (class/render-assignment
      "Homework 11"
      "https://gatech.instructure.com/courses/468386"
      "11/3 - 11/9, 2025")
    (class/render-assignment
      "Exam 3"
      "https://gatech.instructure.com/courses/468386"
      "11/20 - 11/24, 2025")
    (class/render-assignment
      "Lecture: DC4: FFT - Part 1"
      "https://edstem.org/us/courses/82037/lessons/145034/slides/835043"
      "Optional")
    (class/render-assignment
      "Lecture: DC5: FFT - Part 2"
      "https://edstem.org/us/courses/82037/lessons/145035/slides/835068"
      "Optional")
    (class/render-assignment
      "Lecture: GR4: Markov Chains and PageRank"
      "https://edstem.org/us/courses/82037/lessons/145039/slides/835153"
      "Optional")
    (class/render-assignment
      "Lecture: MF5: Max-Flow Generalization"
      "https://edstem.org/us/courses/82037/lessons/145044/slides/835246"
      "Optional")
    (class/render-assignment
      "Lecture: RA1: Modular Arithmetic"
      "https://edstem.org/us/courses/82037/lessons/145054/slides/835450"
      "Optional")
    (class/render-assignment
      "Lecture: RA2: RSA"
      "https://edstem.org/us/courses/82037/lessons/145055/slides/835481"
      "Optional")
    (class/render-assignment
      "Lecture: RA3: Bloom Filters"
      "https://edstem.org/us/courses/82037/lessons/145056/slides/835510"
      "Optional")
  )
)

(define completed
  (list
    (class/render-assignment
      "Lecture: DP1: FIB - LIS - LCS"
      "https://edstem.org/us/courses/82037/lessons/145028/slides/834909"
      "August 18 - August 24, 2025")
    (class/render-assignment
      "Homework 1"
      "https://gatech.instructure.com/courses/468386"
      "8/25 - 8/31, 2025")
  )
)

`([title . "Fall 2025 - Intro to Grad Algorithms (Class only grades exams and the quizzes. Everything else is optional.)"]
  [tasks . [
    ,@(class/render completed todo)]])
