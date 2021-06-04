function add_behavior()
{
    window.onscroll = scroll_title;

    var togglers = document.getElementsByClassName("toggler");

    for (var i = 0; i < togglers.length; i++)
    {
        console.log("added click event: " + i);
        togglers[i].addEventListener('click', function() { toggle_branch(this); } )
    }
};

function scroll_title()
{
    var title = document.getElementById("project_name");
    var left = window.pageXOffset || document.documentElement.scrollLeft;
    title.style.left = left;
    console.log(left);
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