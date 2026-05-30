<div align="center">
    <h1>【 Boofdev's Hyprland dotfiles 】</h1>
    <h3></h3>
</div>

<div align="center"> 
    <h3>A fork of end-4's illogical impulse dotfiles with additional features</h3>
</div>

<div align="center">
    <h2>• differences from origin •</h2>
    <h3></h3>
</div>

This fork adds a number of features and improvements on top of the upstream illogical-impulse dotfiles:

<details>
  <summary>OpenRGB Theming Support</summary>

  - Automatically applies the generated color palette to OpenRGB-compatible devices on startup
  - Integrates with the wallpaper-based theming system so RGB lighting matches the current color scheme
  - Adds `openrgb` to illogical-impulse-fonts-themes dependencies

</details>

<details>
  <summary>GPU Screen Recorder Integration</summary>

  - Integrated [gpu-screen-recorder](https://git.dec05eba.com/gpu-screen-recorder/about/) for high-performance recording
  - Adds gpu-screen-recorder as a dependency of illogical-impulse-screencapture

</details>

<details>
  <summary>Daily Chinese Word Widget</summary>

  - A background widget that displays a daily Chinese word for language learning

</details>

<details>
  <summary>Terminal Theming & Display Tweaks</summary>

  - Splits terminal theming option into two separate settings for more granular control
  - Fixes terminal color options
  - Option to run a custom script on wallpaper change
  - Option to disable the upscale notification

</details>


<div align="center">
    <h2>• overview •</h2>
    <h3></h3>
</div>

> [!WARNING]  
> Hyprland 0.55 update:
> If your distro has not shipped Hyprland 0.55 and/or you're not ready for it, you should switch to the Pre-Hyprland Luaification release (or not update yet, if you're going to do that). See the wiki for more info: [Install](https://ii.clsty.link/en/ii-qs/01setup/#automated-installation) | [Update](https://ii.clsty.link/en/ii-qs/01setup/#updating)

<details> 
  <summary>What this is/isn't</summary>

  - Technically, configuration files
  - Realistically, mostly the custom graphical shell
  - NOT a system setup script: no graphic drivers, no zram setup, etc.
  
</details>

<details> 
  <summary>Notable features</summary>
     
  - **Overview**: Shows open apps with live previews
  - **AI**: Gemini, Ollama, and more
  - **QoL**: screen translation, anti-flashbang, Google Lens
  - **Material themes**: Choose your wallpaper, done, enjoy
  - **Transparent installation**: Every command is shown before it's run
</details>

<details> 
  <summary>Installation</summary>

   - **IMPORTANT: Hyprland 0.55 Update**: If your distro has not shipped Hyprland 0.55 and/or you're not ready for it, you should switch to the Pre-Hyprland Luaification release. See [the wiki](https://ii.clsty.link/en/ii-qs/01setup/) for more info
   - Just run `bash <(curl -s https://ii.clsty.link/get)`
     - Or, clone this repo and run `./setup install`
     - See [the wiki](https://ii.clsty.link/en/ii-qs/01setup/) for more details
   - **Keybinds**: Should be somewhat familiar to Windows or GNOME users. Important ones:
     - `Super`+`/` = keybind list
     - `Super`+`Enter` = terminal


</details>

<details>
  <summary>Software overview</summary>

  | Software                                       | Purpose                                                                                    |
  | ---------------------------------------------- | ------------------------------------------------------------------------------------------ |
  | [Hyprland](https://github.com/hyprwm/hyprland) | The compositor (manages and renders windows)                                               |
  | [Quickshell](https://quickshell.outfoxxed.me/) | A QtQuick-based widget system, used for the status bar, sidebars, etc.                     |
  | Others                                         | See [deps-info.md](https://github.com/hexahigh/dots-hyprland/blob/main/sdata/deps-info.md) |

</details>

<div align="center">
    <h2>• screenshots •</h2>
    <h3></h3>
</div>

<div align="center">
    <img src="assets/illogical-impulse.svg" alt="illogical-impulse logo" style="float:left; width:400;">
</div>

Widget system: Quickshell | Support: Yes

[Showcase video](https://www.youtube.com/watch?v=RPwovTInagE)

| AI, settings app                                                                                                                     | Some widgets                                                                                                                         |
| :----------------------------------------------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------- |
| <img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/5d4e7d07-d0b4-4406-a4c9-ed7ba90e3fe4" /> | <img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/6a32395f-9437-4192-8faf-2951a9e84cbe" /> |
| Window management                                                                                                                    | wow look its orange                                                                                                                  |
| <img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/c51bed8b-3670-4d4c-9074-873be224fb8e" /> | <img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/98703a66-0743-439f-a721-cef7afa6ab95" /> |

<div align="center">
    <h2>• thank you •</h2>
    <h3></h3>
</div>

 - [@end-4](https://github.com/end-4) for making the original illogical impulse dotfiles, which this repo is forked from.
 - [@clsty](https://github.com/clsty) for making the dotfiles accessible by taking care of the install script and many other things
 - [@midn8hustlr](https://github.com/midn8hustlr) for greatly improving the color generation system
 - [@outfoxxed](https://github.com/outfoxxed/) for being extremely supportive in my Quickshell journey
 - Quickshell: [Soramane](https://github.com/caelestia-dots/shell/), [FridayFaerie](https://github.com/FridayFaerie/quickshell), [nydragon](https://github.com/nydragon/nysh)
 - AGS: [Aylur](https://github.com/Aylur/dotfiles/tree/ags-pre-ts), [kotontrion](https://github.com/kotontrion/dotfiles)
 - EWW: [fufexan](https://github.com/fufexan/dotfiles)
 - 
