--============================================================================--
--                          EskaTracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
PLoop(function(_ENV)
  _G.BlockModule = class "BlockModule" (function(_ENV)
    inherit "Scorpio"
    ----------------------------------------------------------------------------
    --                             Methods                                    --
    ----------------------------------------------------------------------------
    __Arguments__ { NEString }
    function IsRegisteredEventByActiveSystem(self, evt)
      if self._ActiveOnEvents and self._ActiveOnEvents:Contains(evt) then
        return true
      end

      if self._InactiveOnEvents and self._InactiveOnEvents:Contains(evt) then
        return true
      end

      return false
    end

    __Arguments__ { NEString }
    function AddActiveEvent(self, evt)
      if not self._ActiveOnEvents then
        self._ActiveOnEvents = List(evt)
      else
        if not self._ActiveOnEvents:Contains(evt) then
          self._ActiveOnEvents:Insert(evt)
        end
      end
    end

    __Arguments__ { NEString }
    function AddInactiveEvent(self, evt)
      if not self._InactiveOnEvents then
        self._InactiveOnEvents = List(evt)
      else
        if not self._InactiveOnEvents:Contains(evt) then
          self._InactiveOnEvents:Insert(evt)
        end
      end
    end

    __Arguments__{ NEString, (NEString + Function)/nil }:Throwable()
    function RegisterEvent(self, evt, handler)
      handler = handler or evt
      if type(handler) == "string" then handler = self[handler] end

      if self:IsRegisteredEventByActiveSystem(evt) then
        local newHandler = function(...)
          if self._Inactive and self._ActiveOnEvents:Contains(evt) then
            self._Active = self._ActiveOnHandler(self, evt, ...)
          end

          -- Call the orig handler only if the module is active
          if self._Active then
            handler(evt, ...)
          end

          -- NOTE: _eventActiveChanged is here for avoiding to call two cond
          -- handler in same event.
          if self._Active and not self._eventActiveChanged then
            if self._InactiveOnEvents then
              if self._InactiveOnEvents:Contains(evt) then
                self._Active = not self._InactiveOnHandler(self, evt, ...)
              end
            else
              self._Active = self._ActiveOnHandler(self, evt, ...)
            end
          end
          self._eventActiveChanged = nil
        end
        super.RegisterEvent(self, evt, newHandler)
      else
        super.RegisterEvent(self, evt, handler)
      end
    end

    --- Call when the module become  active
    function OnActive(self) end
    --- Call when the module become inactive
    function OnInactive(self) end
    ----------------------------------------------------------------------------
    --                         Properties                                     --
    ----------------------------------------------------------------------------
    property "_Active" { TYPE = Boolean, DEFAULT = false, HANDLER = function(self, new)
      if new then
        self:OnActive()
        self._eventActiveChanged = true
      else
        self:OnInactive()
      end
    end }

    -- Ready only, avoid to edit this property
    property "_Inactive" { TYPE = Boolean, GET = function(self) return not self._Active end }

  end)
    ----------------------------------------------------------------------------
    --                                                                        --
    --                         __ActiveOnEvents__                             --
    --                                                                        --
    ----------------------------------------------------------------------------
    class "__ActiveOnEvents__" (function(_ENV)
      inherit "__SystemEvent__"

      function AttachAttribute(self, target, targetType, owner, name)
        if #self > 0 then
          for _, evt in ipairs(self) do
            if not owner:IsRegisteredEventByActiveSystem(evt) then
              local handler = owner:GetRegisteredEventHandler(evt)
              if not handler then
                 handler = function() end
               end
               -- NOTE the order is important, AddActiveEvent must be called
               -- before RegisterEvent
               owner:AddActiveEvent(evt)
               owner:RegisterEvent(evt, handler)
            end
          end
        else
          if not owner:IsRegisteredEventByActiveSystem(evt) then
            local handler = owner:GetRegisteredEventHandler(name)
            if not handler then
              handler = function() end
            end
            -- NOTE the order is important, AddActiveEvent must be called
            -- before RegisterEvent
            owner:AddActiveEvent(name)
            owner:RegisterEvent(name, handler)
          end
        end
        owner._ActiveOnHandler = target
      end
    end)
    ----------------------------------------------------------------------------
    --                                                                        --
    --                         __InactiveOnEvents__                           --
    --                                                                        --
    ----------------------------------------------------------------------------
    class "__InactiveOnEvents__" (function(_ENV)
      inherit "__SystemEvent__"

      function AttachAttribute(self, target, targetType, owner, name)
        if #self > 0 then
          for _, evt in ipairs(self) do
            if not owner:IsRegisteredEventByActiveSystem(evt) then
              local handler = owner:GetRegisteredEventHandler(evt)
              if not handler then
                 handler = function() end
               end
               -- NOTE the order is important, AddActiveEvent must be called
               -- before RegisterEvent
               owner:AddInactiveEvent(evt)
               owner:RegisterEvent(evt, handler)
            end
          end
        else
          if not owner:IsRegisteredEventByActiveSystem(evt) then
            local handler = owner:GetRegisteredEventHandler(name)
            if not handler then
              handler = function() end
            end
            -- NOTE the order is important, AddActiveEvent must be called
            -- before RegisterEvent
            owner:AddInactiveEvent(name)
            owner:RegisterEvent(name, handler)
          end
        end
        owner._InactiveOnHandler = target
      end
    end)
end)
