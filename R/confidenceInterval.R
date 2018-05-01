#' Estimate confidence intervals for breakpoints
#'
#' Estimate confidence intervals for breakpoints by going outwards from the breakpoint read by read, and multiplying the probability that the read doesn't belong to the assigned segment.
#'
#' @param breaks Genotyped breakpoints as outputted from function \code{\link{GenotypeBreaks}}.
#' @param fragments Read fragments from function \code{\link{readBamFileAsGRanges}}.
#' @param conf Desired confidence interval of localized breakpoints.
#' @inheritParams GenotypeBreaks
#' @return A \code{\link[GenomicRanges]{GRanges}} object of breakpoint ranges for a given confidence interval in \code{conf}.
#' @author Aaron Taudt, David Porubsky
#' @export
#' @examples
#'## Get an example file  
#'exampleFolder <- system.file("extdata", "example_bams", package="strandseqExampleData")
#'exampleFile <- list.files(exampleFolder, full.names=TRUE)[1]
#'## Load the file
#'fragments <- readBamFileAsGRanges(exampleFile, pairedEndReads=FALSE)
#'## Calculate deltaW values
#'dw <- deltaWCalculator(fragments)
#'## Get significant peaks in deltaW values
#'breaks <- breakSeekr(dw)
#'## Genotype regions between breakpoints
#'gbreaks <- GenotypeBreaks(breaks, fragments)
#'## Calculate confidence intervals of genotyped breakpoints
#'confint <- confidenceInterval(gbreaks, fragments, background=0.02)
#'
confidenceInterval <- function(breaks, fragments, background=0.05, conf=0.99) {

    ## Assign probabilities for a read belonging to genotype at breakpoint
    probs <- array(NA, dim = c(2,2,6), dimnames = list(strand=c('-','+'), side=c('left','right'), genotype=c('ww-wc','ww-cc','wc-ww','wc-cc','cc-ww','cc-wc')))
    calcProbs <- function(leftprob) {
        return( (leftprob + background) / (1 + 2*background) )
    }
    probs[,,'ww-wc'] <- c(calcProbs(1/3), 1-background, calcProbs(1-1/3), background)
    probs[,,'ww-cc'] <- c(background, 1-background, 1-background, background)
    probs[,,'wc-ww'] <- c(calcProbs(1-1/3), background, calcProbs(1/3), 1-background)
    probs[,,'wc-cc'] <- c(background, calcProbs(2/3), 1-background, calcProbs(1-2/3))
    probs[,,'cc-ww'] <- c(1-background, background, background, 1-background)
    probs[,,'cc-wc'] <- c(1-background, calcProbs(1-2/3), background, calcProbs(2/3))

    ## Do chromosomes one by one
    breaks.conf <- GenomicRanges::GRangesList()
    seqlevels(breaks.conf) <- seqlevels(breaks)
    for (chrom in unique(seqnames(breaks))) {
        cbreaks <- breaks[seqnames(breaks) == chrom]
        cfrags <- fragments[seqnames(fragments) == chrom]
        #cfrags <- GenomicRanges::sort(cfrags, ignore.strand=TRUE)
        if (length(cbreaks) > 0) {
            for (ibreak in 1:length(cbreaks)) {
                genotype <- cbreaks$genoT[ibreak]
                # Left side
                ind <- which(start(cfrags) < start(cbreaks)[ibreak])
                ind <- ind[length(ind)]
                p <- 1
                i1 <- -1
                while (p > 1-conf) {
                    i1 <- i1+1
                    if (ind-i1 <= 0) {
                        i1 = i1 - 1 
                        break
                    }
                    strandofread <- as.character(strand(cfrags)[ind-i1])
                    p <- p * probs[strandofread, 'left', genotype]
                }
                start(cbreaks)[ibreak] <- start(cfrags)[ind-i1]
                # Right side
                ind <- which(end(cfrags) > end(cbreaks)[ibreak])
                ind <- ind[1]
                p <- 1
                i1 <- -1
                while (p > 1-conf) {
                    i1 <- i1+1
                    if (ind+i1 > length(cfrags)) {
                        i1 = i1 - 1
                        break
                    }
                    strandofread <- as.character(strand(cfrags)[ind+i1])
                    p <- p * probs[strandofread, 'right', genotype]
                }
                end(cbreaks)[ibreak] <- end(cfrags)[ind+i1]
            }
        }
        breaks.conf[[chrom]] <- cbreaks
    }
    breaks.conf <- unlist(breaks.conf, use.names = FALSE)
    return(breaks.conf)

}



#' Estimate confidence intervals for breakpoints
#' 
#' Estimate confidence intervals for breakpoints by going outwards from the breakpoint read by read, and performing a binomial test of getting the observed or a more extreme outcome, given that the reads within the confidence interval belong to the other side of the breakpoint.
#' 
#' @param breaks Genotyped breakpoints as outputted from function \code{\link{GenotypeBreaks}}.
#' @param fragments Read fragments from function \code{\link{readBamFileAsGRanges}}.
#' @param conf Desired confidence interval of localized breakpoints.
#' @inheritParams GenotypeBreaks
#' @return A \code{\link[GenomicRanges]{GRanges}} object of breakpoint ranges for a given confidence interval in \code{conf}.
#' @author Aaron Taudt, David Porubsky
#' @export
#' @examples
#'## Get an example file  
#'exampleFolder <- system.file("extdata", "example_bams", package="strandseqExampleData")
#'exampleFile <- list.files(exampleFolder, full.names=TRUE)[1]
#'## Load the file
#'fragments <- readBamFileAsGRanges(exampleFile, pairedEndReads=FALSE)
#'## Calculate deltaW values
#'dw <- deltaWCalculator(fragments)
#'## Get significant peaks in deltaW values
#'breaks <- breakSeekr(dw)
#'## Genotype regions between breakpoints
#'gbreaks <- GenotypeBreaks(breaks, fragments)
#'## Calculate confidence intervals of genotyped breakpoints
#'confint <- confidenceInterval.binomial(gbreaks, fragments, background=0.02)
#' 
confidenceInterval.binomial <- function(breaks, fragments, background=0.02, conf=0.99) {
  
    ## Assign probabilities for a read belonging to genotype at breakpoint
    probs <- array(NA, dim = c(2,2,6), dimnames = list(strand=c('-','+'), side=c('left','right'), genotype=c('ww-wc','ww-cc','wc-ww','wc-cc','cc-ww','cc-wc')))
    probs[,,'ww-wc'] <- c(0.5, 0.5, 1-background, background)
    probs[,,'ww-cc'] <- c(background, 1-background, 1-background, background)
    probs[,,'wc-ww'] <- c(1-background, background, 0.5, 0.5)
    probs[,,'wc-cc'] <- c(background, 1-background, 0.5, 0.5)
    probs[,,'cc-ww'] <- c(1-background, background, background, 1-background)
    probs[,,'cc-wc'] <- c(0.5, 0.5, background, 1-background)
  
    ## Do chromosomes one by one
    breaks.conf <- GenomicRanges::GRangesList()
    seqlevels(breaks.conf) <- seqlevels(breaks)
    for (chrom in unique(seqnames(breaks))) {
        cbreaks <- breaks[seqnames(breaks) == chrom]
        cfrags <- fragments[seqnames(fragments) == chrom]
        #cfrags <- GenomicRanges::sort(cfrags, ignore.strand=TRUE)
        if (length(cbreaks) > 0) {
            for (ibreak in 1:length(cbreaks)) {
                genotype <- cbreaks$genoT[ibreak]
                # Left side
                ind <- which(start(cfrags) < start(cbreaks)[ibreak])
                ind <- ind[length(ind)]
                p <- 1
                i1 <- -1
                numReads <- c('-'=0, '+'=0)
                while (p > 1-conf) {
                    i1 <- i1+1
                    if (ind-i1 <= 0) {
                        i1 = i1 - 1 
                        break
                    }
                    strandofread <- as.character(strand(cfrags)[ind-i1])
                    numReads[strandofread] <- numReads[strandofread] + 1
                    strandtocompare <- names(which(probs[, 'left', genotype] >= probs[, 'right', genotype]))
                    p <- stats::pbinom(q = numReads[strandtocompare], size = sum(numReads), prob = probs[strandofread, 'left', genotype])
                }
                start(cbreaks)[ibreak] <- start(cfrags)[ind-i1]
                # Right side
                ind <- which(end(cfrags) > end(cbreaks)[ibreak])
                ind <- ind[1]
                p <- 1
                i1 <- -1
                numReads <- c('-'=0, '+'=0)
                while (p > 1-conf) {
                    i1 <- i1+1
                    if (ind+i1 > length(cfrags)) {
                        i1 = i1 - 1
                        break
                    }
                    strandofread <- as.character(strand(cfrags)[ind+i1])
                    numReads[strandofread] <- numReads[strandofread] + 1
                    strandtocompare <- names(which(probs[, 'right', genotype] >= probs[, 'left', genotype]))
                    p <- stats::pbinom(q = numReads[strandtocompare], size = sum(numReads), prob = probs[strandofread, 'right', genotype])
                }
                end(cbreaks)[ibreak] <- end(cfrags)[ind+i1]
            }
        }
        breaks.conf[[chrom]] <- cbreaks
    }
    breaks.conf <- unlist(breaks.conf, use.names = FALSE)
    return(breaks.conf)
  
}