# How to set up a VVV{YY} School

**YY** is the school year (e.g. **17**, **18**...)

## VVV{YY} School repository

The repository will be named **vvv-school/vvv{yy}** (e.g. [vvv-school/vvv17](https://github.com/vvv-school/vvv17)).

Everything is mostly done, since we can  [**duplicate** the repository](https://help.github.com/articles/duplicating-a-repository/#mirroring-a-repository) **vvv{yy-1}** into **vvv{yy}**.

Then, do the following steps:
- If you didn't do it while creating the new repository, edit the **description** and the **website** fields of the repository page with, respectively, **Resources for VVV{YY} School** and **https://vvv-school.github.io/vvv{yy}**.
- Within [vvv-school](https://github/vvv-school), [create two **teams**](https://help.github.com/articles/creating-a-team): **vvv{yy}-teachers** and **vvv{yy}-students**. Start off filling in the teachers team for the time being, while we will be waiting for all students to sign up on GitHub. Remember that teams visibility is restricted to the organization's members, hence don't spread out links to them, since non-members won't be able to access teams info.
- Add up **vvv{yy}-students** as [**team with read permission**](https://help.github.com/articles/managing-team-access-to-an-organization-repository) to **vvv{yy}**, so that students can edit the Wiki.
- Replace all the links in **README.md**, **teachers.md** and **students.md** files.
- Create a [**welcome issue**](https://github.com/vvv-school/vvv17/issues/1) in **Q&A**. Don't forget to replace links therein.
- Create just one page in the **Wiki** containing the [**instructions to follow before arriving at VVV**](https://github.com/vvv-school/vvv17/wiki/Before-arriving-at-VVV) and link it from within the Wiki home page. We have a [**template**](../instructions/before-arriving-at-vvv.md) for it, but you would need to tailor it slightly in order to adjust links to resources (e.g. new Q&A, new mailing list...). If there are instructions that are likely to be reused for upcoming schools, don't forget to **update the template** accordingly.
- [Configure the **GitHub Pages**](https://help.github.com/articles/configuring-a-publishing-source-for-github-pages/#enabling-github-pages-to-publish-your-site-from-master-or-gh-pages) to publish from the **`master`** branch. The file **`_config.yml`** used by GitHub Pages to set up the style should be already contained inside (thanks to duplication).
- Fill in the file **gradebook.md** with proper links to the GitHub page of the [courses repositories](#vvvyy-school-courses-repositories).

## Set up VVV{YY} School courses organizations

During **vvv{yy}** school, teachers will be giving **frontal lessons** and **hands-on sessions** regarding diverse courses, e.g. **kinematics**, **dynamics**, **vision** and so on.

### Hands-on
**Hands-on** are repositories stored in [vvv-school](https://github.com/vvv-school) organization, which we handle using the [**GitHub Education**](https://education.github.com) platform.

There are two categories of hands-on:

#### Tutorials
>A tutorial is a repository containing complete code to cover a particular aspect of the course. During lessons, teachers and students can work on it together. Tutorials will be therefore assigned within the classroom, even though students are not required to provide any solution (it's already complete); thus, their score is low (e.g. **1,2**). A tutorial may or may not provide a [**smoke-test**](https://github.com/vvv-school/vvv-school.github.io/blob/master/instructions/how-to-complete-assignments.md#smoke-testing); at any rate, it won't be used by [**automatic grading**](#automatic-grading) process.

>[**tutorial_cartesian-interface**](https://github.com/vvv-school/tutorial_cartesian-interface) is an example of tutorial you can design yours from.

>Be tidy and call your tutorials with the prefix **tutorial_**.

#### Assignments
>An assignment is a repository that contains **starter code** students are required to complete with their own solutions. To run the [**automatic grading**](#automatic-grading) process based on assignments, teachers responsible for the course need to code a [**smoke-test**](https://github.com/vvv-school/vvv-school.github.io/blob/master/instructions/how-to-complete-assignments.md#smoke-testing) inside the assignment. Typically, assignments have higher scores (**> 2**) depending on their difficulty.

>[**assignment_make-it-roll**](https://github.com/vvv-school/assignment_make-it-roll) is an example of assignment you can design yours from.

>Be tidy and call your assignments with the prefix **assignment_**.


Thereby, to deal with students assignments for each course, we have to create the dedicated organization **vvv{yy}-{course}** (e.g. [vvv17-kinematics](https://github.com/vvv17-kinematics)). This choice allows us to use a [**GitHub Classroom**](https://classroom.github.com) specific to each course as well as to avoid cluttering the main [vvv-school](https://github.com/vvv-school) organization with lots of students repositories that will be automatically generated by means of the classroom process.

Therefore, for each course, do:
- [Create the **organization**](https://help.github.com/articles/creating-a-new-organization-from-scratch) **vvv{yy}-course**.
- It's not strictly necessary to give all teachers read/write permissions to the course organization: course maintainer is just enough :wink:
- [Create a brand new **classroom**](https://classroom.github.com/classrooms/new) on top of **vvv{yy}-{course}**. You should see in **vvv{yy}-{course}** the list; if not, grant GitHub access first (clik on the link at the bottom of the page).


### VVV{YY} School courses repositories

Each course is managed through a **course repository**, which is thus named **vvv{yy}-{course}/vvv{yy}-{course}.github.io** (e.g. [vvv17-kinematics/vvv17-kinematics.github](https://github.com/vvv17-kinematics/vvv17-kinematics.github.io)), and aims to automatically handle the **course gradebook**.

Then, let's create this last repository! Also here, everything is mostly already done, since we can [**duplicate** the repository](https://help.github.com/articles/duplicating-a-repository/#mirroring-a-repository) **vvv{yy-1}-{course}/vvv{yy-1}-{course}.github.io** into **vvv{yy}-{course}/vvv{yy}-{course}.github.io**.

Consider these further notes:

- If you didn't do it while creating the new repository, edit the **description** and the **website** fields of the repository page with, respectively, **Gradebook of VVV{YY} Robot {course}** and **https://vvv{yy}-{course}.github.io**.
- **GitHub Pages** are already enabled by default, given the chosen name of the repository. The file **`_config.yml`** used by GitHub Pages to set up the style should be already contained inside (thanks to duplication).

#### Gear up for automatic grading

Within the course repository, you have to fill in the **data.json** file containing info on **tutorials** and **assignments** regarding this particular **{course}**.

The format is pretty much intuitive. Here's an example:
```json
{
    "tutorials": [
        {
            "name": "tutorial_gaze-interface",
            "url": "https://github.com/vvv-school/tutorial_gaze-interface.git",
            "score": 1
        },
        {
            "name": "tutorial_cartesian-interface",
            "url": "https://github.com/vvv-school/tutorial_cartesian-interface.git",
            "score": 1
        }      
    ],
    
    "assignments": [
        {
            "name": "assignment_make-it-roll",
            "url": "https://github.com/vvv-school/assignment_make-it-roll",
            "score": 5
        }    
    ]    
}
```
Be careful, a repository can be **listed only once**.

## Automatic grading

### Launch the challenge

Once you're all set, you can [create an **individual assignment**]() from the course **GitHub Classrom** dashboard.

These are the settings we have to use:
- **Your assignment title**: make up a nice name.
- **Your assignment repository prefix**: must be equal to the name of the **starter code**.
- Tick on **Public** :white_check_mark:
- **Don't give students** _Admin permissions_ on their repository :x:
- **Add your starter code from GitHub**: select the name of your tutorial and/or assignment from [vvv-school](https://github.com/vvv-school).

You'll be given a link you ought to share with students. The easiest and the most collaborative way is to post it on the **Q&A** system: https://github.com/vvv-school/vvv{yy}/issues.

### Update the gradebook