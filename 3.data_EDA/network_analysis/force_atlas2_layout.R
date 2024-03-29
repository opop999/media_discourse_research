##################### Force Atlas 2 function ########################################################

layout.forceatlas2 <- function(g, iterations = 100, linlog = FALSE, pos = NULL, nohubs = FALSE,
                               k = 400, gravity = 1, ks = 0.1, ksmax = 10, delta = 1, center = NULL,
                               tolerate = 0.1, dim = 2, plotstep = 10, plotlabels = TRUE) {
  ####  g is a igraph network
  ####  iterations is the number of iterations to be performed
  ####  linlog is a variant which uses logarithmic attraction force F <- log (1+F)
  ####  pos is the table (NumberOfNodes x dimension) of the initial locations of points, if specified
  ####  nohubs is a variant in which nodes with high indegree have more central position than nodes with outdegree (for directed graphs)
  ####  k is the repel constant : the greater the constant k the stronger the repulse force between points
  ####  gravity is the gravity constant : indicates how strongly the nodes should be attracted to the center of gravity
  ####  ks is the speed constant : the greater the value of ks the more movement the nodes make under the acting forces
  ####  ksmax limits the speed from above
  ####  delta is the parameter to modify attraction force; means that weights are raised to the power = delta
  ####  center is the center of gravity
  ####  tolerance is the tolerance to swinging constant
  ####  dim is the dimension
  ####  plotstep is the frequency of plotting intermediate iterations
  ####  plotlabels is TRUE if the labels should be included in the intermediate interations plot

  A <- igraph::get.adjacency(g,
    type = "both",
    attr = NULL, edges = FALSE, names = TRUE,
    sparse = FALSE
  )

  #### center of gravity is by default set to the origin
  if (is.null(center)) center <- rep(0, dim)

  nnodes <- nrow(A)
  #### Binary will be a matrix of simple incidence (0-not connected, 1-connected)
  Binary <- A
  Binary[Binary != 0] <- 1
  #### Deg will be a vector of the degrees of vertices
  Deg <- rowSums(Binary)
  #### Forces1 will be a table containing all the sums of forces acting on points at a step
  Forces1 <- matrix(0, nrow = dim, ncol = nnodes)

  #### If there are no initial coordinates of points,
  #### they are chosen at random from 1000^dim square
  if (is.null(pos)) {
    difference <- 2000 / (nnodes * dim)
    position <- matrix(sample(seq(-1000, 1000, difference), nnodes * dim), nnodes, dim)
  } else {
    position <- pos
  }

  #### None of the nodes should be exactly at the center of gravity###
  temp <- which(position[, 1] == center[1])
  for (index in 2:ncol(position)) {
    temp <- intersect(temp, which(position[, index] == center[index]))
  }
  position[temp, ] <- center + 0.01
  rm(index, temp)

  #### displacement will be a matrix of points' movement at the current iteration
  displacement <- matrix(rep(0, dim * nnodes), dim, nnodes)

  m <- nrow(position)

  for (iteration in 1:iterations)
  {
    displacement <- displacement * 0
    #### Forces2 is the table of the forces from previous step
    #### Forces1 is the table of the forces from current step
    Forces2 <- Forces1
    Forces1 <- matrix(, nrow = dim, ncol = 0)

    #### Calculate the Forces for each node
    ### Distance matrix between all nodes
    distances <- as.matrix(dist(position))
    distances[which(distances < 0.01)] <- 0.01 # We impose a minimum distance
    ### Each element of the list contains a matrix with the j = 1,2,..., dim dimension of the unitary vector 1
    mylist <- vector("list", dim)
    for (j in 1:dim) {
      mylist[[j]] <- (tcrossprod(position[, j], rep(1, m)) - tcrossprod(rep(1, m), position[, j])) / distances
    }
    ### Calculate the repulsion Force
    Fr <- k * ((tcrossprod(rep(1, m), Deg) + 1) * (tcrossprod(Deg, rep(1, m)) + 1)) / distances

    # The classical attraction force is just based on distance
    Fa <- distances
    # The linlog mode calculates the attraction force as log(1+d(n1,n2))
    if (linlog) {
      Fa <- log(1 + Fa)
    }
    # Edge weights. The edges are weighted based on parameter delta. delta=0 implies no weight
    Fa <- (A^delta) * Fa

    # Dissuade Hubs. This mode is meant to grant authorities (nodes with high indegree)
    # a more central position than hubs (nodes with high outdegree)
    if (nohubs) {
      Fa <- Fa / (tcrossprod(Deg, rep(1, m)) + 1)
    }

    ### Function to calculate the Attraction and Repulsion forces
    Farfunction <- function(x) rowSums(x * (Fr - Fa), na.rm = T)
    ### And we aggregate it over all dimensions
    Far <- do.call(rbind, lapply(mylist, Farfunction))
    ### Unitary Vector 2, the directions between each point and the center
    uv2 <- apply(matrix(rep(center, m), nrow = m, byrow = T) - position, 1, function(x) x / sqrt(sum(x^2)))
    ### The gravity force
    # Fg <- uv2*matrix(rep(gravity*(rowSums(A)+1),dim),nrow=dim,byrow=T)
    Fg <- uv2 * matrix(rep(gravity * (Deg + 1), dim), nrow = dim, byrow = T)
    ### Forces 1 is the sum between all forces: Far (Fa + Fr) and Fg
    Forces1 <- Far + Fg
    Forces1 <- round(Forces1, 2) # Use the first two decimals for the Forces.

    #### Swing is the vector of the swingings of all points
    swing <- abs(colSums((Forces1 - Forces2)^2)^(1 / 2))
    Global_swing <- sum((Deg + 1) * swing)

    #### tra is the vector of the traction of all points
    tra <- abs(colSums((Forces1 + Forces2)^2)^(1 / 2)) / 2
    Global_tra <- sum((Deg + 1) * tra)

    #### Global speed calculation
    Global_speed <- tolerate * Global_tra / Global_swing
    #### speed is the vector of individual speeds of points
    speed <- ks * Global_speed / (1 + Global_speed * (swing)^(1 / 2))

    #### Imposing constrains on speed
    speed_constrain <- ksmax / abs(colSums((Forces1^2))^(1 / 2))
    speed <- ifelse(speed >= speed_constrain, speed_constrain, speed)

    #### calculating displacement and final position of points after iteration
    displacement <- Forces1 * t(matrix(rep(speed, dim), nnodes, dim))
    position <- position + t(displacement)

    #### Iteration plot. This is simply to see the evolution of the positions over iterations
    #### Is much faster to visualize directly using R base plots instead of igraph plots

    if (!plotstep == 0 & dim == 2) {
      if (iteration %% plotstep == 0) {
        plot(position, main = paste0("iteration: ", iteration), xlab = "", ylab = "")
        if (plotlabels) text(position, labels = V(g)$name, cex = 0.7, pos = 3)
      }
    }
  }
  return(position)
}
