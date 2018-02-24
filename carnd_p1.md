Title: Finding Lane Lines, Part 1
Date: 2016-02-24 12:46
Category: SelfDrivingCar 

Pipeline Overview
=================

Here is a simple project for finding the lane lines on a road image. The
pipeline consisted of the following steps:

1.  First, we convert the image to grayscale. This is because the
    subsequent algorithms to be run on this, such as Canny edge
    detection, only work on grayscale images. Note that we do this by
    using the OpenCV function `cv2.cvtColor(img, cv2.COLOR_RGB2GRAY`,
    which treats all of the three color channels (red, green, blue)
    equally.

2.  Then, we apply Canny edge detection. Canny edge detection works by
    computing the *gradient* (difference between adjacent pixels) of the
    image, and highlights only the places where this gradient is
    highest - i.e., where there is an edge. Note that this effectively
    turns a segment of a lane line (a dotted line) into a quadrilateral,
    and turns a solid lane line into two edges.

3.  The output of Canny edge detection is just a pixel bitmap showing
    which pixels are part of edges. Now we need to turn these pixels
    into lines. To do this we use the Hough transform, and algorithm
    which does the following:

    1.  Considers the “space of possible lines” defined by $\theta$ (the
        angle of the line), and $\rho$ (the shortest distance of the
        line from the origin) - this is referred to as the “Hough
        space”.

    2.  Each highlighted point defines a curve in the Hough space
        representing the possible lines that contain that point.

    3.  Points in Hough space where lots of the above lines intersect
        represent lines in the original space (the more Hough curves
        intersect at that point in Hough space, the longer that line is)

4.  This process is likely to generate multiple lines for each lane
    line, so we must now combine these lines into just two lines - one
    on the left side and one on the right side. We do this as follows:

    1.  Divide up the lines into two categories: one with negative slope
        (on the left) and one with positive slope (on the right). The
        negative slope is on the left because the X axis goes from left
        to right, but the Y axis goes from the top dow.

    2.  In each of these categories, compute the *smallest* (absolute
        value of) slope, where slope here is defined as $\frac{x}{y}$ -
        note that this is different from how slope is usually defined.
        We do it this way so that a nearly vertical line will not cause
        numerical issues due to the extremely high slope (and we expect
        nearly vertical lines to be more frequent than nearly horizontal
        lines(

    3.  On each side, we consider only Hough lines with a slope of no
        more than 0.2 away from this “smallest slope”. The purpose of
        this is to filter out any lane lines other than the lines that
        bound the lane the car is in (a lane line multiple lanes over
        will have a higher slope)

    4.  We compute the average of the slopes of these lines to get the
        overall slope of the lane line, and then compute the intercept
        by fitting a line of the given slope through the endpoints of
        all the Hough lines.

5.  Then we draw the overall lane lines.

An example of this in action is here:

It is also possible to use this algorithm to annotate the lane lines in
a video by applying the above algorithm to each frame in the video. When
I did this I noticed that the drawn lane lines jumped around a lot from
frame to frame even though the actual lane lines do not appear to move
that much. Thus I changed my algorithm in this case to compute the slope
of each line in a given frame as (0.95 \* slope of line from previous
frame) + (0.05 \* observed average slope of the Hough lines as described
above). Thus this significantly dampens the frame-to-frame vibrations.

The code to generate this is in [a relative link](p1.ipynb).

Discussions and Improvements
============================

Here are some of the shortcomings of this algorithm and ways it could be
improved. I plan to implement these and other improvements in a future
project.

1.  The slopes of the Hough lines appear to change a lot from frame to
    frame spuriously. It is likely that this is because the edges
    obtained by the Canny edge detection are only one pixel wide (all
    the pixels in the “middle” of the lane line are thrown out) so a
    change in even a few of these pixels may significantly change the
    slope. A better approach may be to note that we don’t really care
    about the *edges* of the lane line per se (the “lane line” is really
    a thin quadrilateral) what we care about is the overall lane line.
    Therefore, a better approach may be to not use Canny edge detection
    at all. A better approach may be to do the following:

    1.  Use thresholding to identify which pixels in the image are
        likely part of lane lines. for instance, any white or yellow
        pixels are likely part of lane lines. So the thresholding could
        be based on just the red and green color channels, since yellow
        has high red and green but low blue.

    2.  Use a flood fill or similar algorithm to segment these “likely
        pixels” into contiguous groups.

    3.  Try to identify which contiguous groups are lane lines on the
        road (as opposed to other objects such as white or yellow cars).
        Note that a lane line or lane line segment is expected to be
        long and thin. Thus, if one took all the $(x,y)$ coordinates of
        pixels in a lane line and did PCA on them, one would expect to
        see one very large principal component and one much smaller
        principal component. This pattern could be easily identified.

    4.  Once we have a contiguous group of pixels that represents a lane
        line, we can fit a line through it (e.g. using a least squares
        fit) to get the slope and intercept.

2.  The smoothing technique used between frames in the video works well
    for the test videos in this project where the car is moving roughly
    straight, but may not work well in a scenario where the car is
    changing lanes so the slope of the lane lines actually is changing
    significantly - it might be slow to catch up. A better solution here
    may be a Kalman filter which stores as its state both the current
    slope and a rate of change in slope. Thus if the car was e.g.
    changing lanes, where the lane line’s slope is smoothly changing,
    the filter would pick up on this and track it.

3.  The identifying of each lane line by a slope and intercept assumes
    that it is a straight line. This may not be true if the road is
    curving or if there is a hill in front of the car This is a major
    flaw because both of these situations are likely to require action
    by a self-driving car, so the car would want to know about it. A
    solution here may be to, after the lane line segments on the road
    have been identified as described above, to use some sort of
    clustering algorithm to find “clusters” of these line segments in
    Hough space, and assume that similar clusters represent the same
    lane lines. This would also mean that the algorithm wouldn’t need to
    assume that there are two primary lane lines, one on each side - it
    could detect other things that look like lane lines.
