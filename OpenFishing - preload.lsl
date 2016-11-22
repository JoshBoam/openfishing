default
{
    changed(integer iChange)
    {
        if (iChange & CHANGED_LINK) {
            if (llAvatarOnSitTarget()!=NULL_KEY) {
                llPreloadSound("aww");
                llPreloadSound("bite");
                llPreloadSound("reel_in");
                llPreloadSound("yay");
            }
        }
    }
}