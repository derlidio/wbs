function add_behavior()
{
    window.onscroll = scroll_title;

    var togglers = document.getElementsByClassName("toggler");

    for (var i = 0; i < togglers.length; i++)
    {
        togglers[i].addEventListener('click', function() { toggle_branch(this); } )
    }
};

function scroll_title()
{
    var title = document.getElementById("project_name");
    var container = document.getElementById("container");

    var left = window.pageXOffset || document.documentElement.scrollLeft;
    var limit = container.style.offsetWidth - window.innerWidth;

    if (limit < 0) limit = 0;

    title.style.left = left > limit? limit : left;
}

function toggle_branch(ref)
{
    var index = ref.id.split(":")[1];

    var ramification = document.getElementById("ramification:" + index);

    if (ramification.classList.contains("hidden"))
    {
        ramification.classList.remove("squeezed");
        ramification.classList.remove("hidden");        
    }
    else
    {        
        ramification.classList.add("hidden");
        setTimeout( function(){ ramification.classList.add("squeezed"); }, 250);
    }
};