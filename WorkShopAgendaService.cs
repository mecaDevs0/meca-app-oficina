using AutoMapper;
using Meca.ApplicationService.Interface;
using Meca.Data.Entities;
using Meca.Data.Entities.Auxiliaries;
using Meca.Domain;
using Meca.Domain.ViewModels;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using System.Threading.Tasks;
using UtilityFramework.Application.Core3;
using UtilityFramework.Infra.Core3.MongoDb.Business;
using System;

namespace Meca.ApplicationService.Services
{
    public class WorkshopAgendaService : ApplicationServiceBase<WorkshopAgenda>, IWorkshopAgendaService
    {
        private readonly IBusinessBaseAsync<WorkshopAgenda> _workshopAgendaRepository;
        private readonly IBusinessBaseAsync<Workshop> _workshopRepository;
        private readonly IMapper _mapper;

        // CONSTRUTOR CORRIGIDO - SEM base() e COM SetAccess()
        public WorkshopAgendaService(
            IMapper mapper,
            IBusinessBaseAsync<WorkshopAgenda> workshopAgendaRepository,
            IBusinessBaseAsync<Workshop> workshopRepository,
            IHttpContextAccessor httpContextAccessor)
        {
            _mapper = mapper;
            _workshopAgendaRepository = workshopAgendaRepository;
            _workshopRepository = workshopRepository;
            
            // 🔑 SOLUÇÃO CRÍTICA: Inicializar _access automaticamente
            SetAccess(httpContextAccessor);
        }

        public async Task<WorkshopAgendaViewModel> GetWorkshopAgenda(string id = null)
        {
            try
            {
                // ✅ _access já está inicializado no construtor
                if (_access == null || string.IsNullOrEmpty(_access.UserId))
                {
                    CreateNotification("Acesso não autorizado");
                    return new WorkshopAgendaViewModel();
                }

                var workshopEntity = await _workshopRepository.FindByIdAsync(_access.UserId);
                if (workshopEntity == null)
                {
                    CreateNotification(DefaultMessages.WorkshopNotFound);
                    return new WorkshopAgendaViewModel();
                }

                var workshopAgendaEntity = await _workshopAgendaRepository.FindOneByAsync(x =>
                    x.Workshop.Id == workshopEntity.GetStringId());

                if (workshopAgendaEntity == null)
                {
                    return new WorkshopAgendaViewModel
                    {
                        Monday = new WorkshopAgendaAuxViewModel { Open = false },
                        Tuesday = new WorkshopAgendaAuxViewModel { Open = false },
                        Wednesday = new WorkshopAgendaAuxViewModel { Open = false },
                        Thursday = new WorkshopAgendaAuxViewModel { Open = false },
                        Friday = new WorkshopAgendaAuxViewModel { Open = false },
                        Saturday = new WorkshopAgendaAuxViewModel { Open = false },
                        Sunday = new WorkshopAgendaAuxViewModel { Open = false }
                    };
                }

                return _mapper.Map<WorkshopAgendaViewModel>(workshopAgendaEntity);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[SERVICE ERROR] Exception in GetWorkshopAgenda: {ex.Message}");
                CreateNotification($"Erro ao obter agenda: {ex.Message}");
                return new WorkshopAgendaViewModel();
            }
        }

        public async Task<WorkshopAgendaViewModel> RegisterOrUpdate(WorkshopAgendaViewModel model)
        {
            try
            {
                Console.WriteLine($"[SERVICE-DEBUG] Entrou em RegisterOrUpdate.");
                Console.WriteLine($"[SERVICE-DEBUG] Model recebido: {(model == null ? "NULO" : "NÃO NULO")}");

                if (model != null)
                {
                    Console.WriteLine($"[SERVICE-DEBUG] Model.Id: {model.Id}");
                    Console.WriteLine($"[SERVICE-DEBUG] Model.Monday.Open: {model.Monday?.Open}");
                    Console.WriteLine($"[SERVICE-DEBUG] Model.Monday.StartTime: {model.Monday?.StartTime}");
                }

                Console.WriteLine($"[SERVICE-DEBUG] Iniciando validação de acesso...");
                
                // ✅ _access já está inicializado no construtor
                if (_access == null)
                {
                    Console.WriteLine($"[SERVICE-DEBUG] _access é NULO - ACESSO NÃO AUTORIZADO");
                    CreateNotification("Acesso não autorizado");
                    return null;
                }

                Console.WriteLine($"[SERVICE-DEBUG] _access OK. UserId: {_access.UserId}");

                if (string.IsNullOrEmpty(_access.UserId))
                {
                    Console.WriteLine($"[SERVICE-DEBUG] _access.UserId é NULO/VAZIO");
                    CreateNotification("Identificador de usuário inválido");
                    return null;
                }

                Console.WriteLine($"[SERVICE-DEBUG] Buscando workshop por UserId: {_access.UserId}");

                var workshopEntity = await _workshopRepository.FindByIdAsync(_access.UserId);
                
                if (workshopEntity == null)
                {
                    Console.WriteLine($"[SERVICE-DEBUG] Workshop não encontrado para o UserId: {_access.UserId}");
                    CreateNotification(DefaultMessages.WorkshopNotFound);
                    return null;
                }

                Console.WriteLine($"[SERVICE-DEBUG] Workshop encontrado. Id: {workshopEntity.GetStringId()}");

                WorkshopAgenda workshopAgendaEntity;

                if (string.IsNullOrEmpty(model.Id))
                {
                    Console.WriteLine($"[SERVICE-DEBUG] Model.Id vazio - CRIANDO NOVA AGENDA");
                    
                    workshopAgendaEntity = new WorkshopAgenda
                    {
                        Sunday = MapDay(model.Sunday),
                        Monday = MapDay(model.Monday),
                        Tuesday = MapDay(model.Tuesday),
                        Wednesday = MapDay(model.Wednesday),
                        Thursday = MapDay(model.Thursday),
                        Friday = MapDay(model.Friday),
                        Saturday = MapDay(model.Saturday),
                        Workshop = _mapper.Map<WorkshopAux>(workshopEntity)
                    };

                    Console.WriteLine($"[SERVICE-DEBUG] Entidade criada. Salvando no banco...");
                    await _workshopAgendaRepository.CreateAsync(workshopAgendaEntity);
                    Console.WriteLine($"[SERVICE-DEBUG] CreateAsync executado com sucesso.");
                }
                else
                {
                    Console.WriteLine($"[SERVICE-DEBUG] Model.Id preenchido: {model.Id} - ATUALIZANDO AGENDA EXISTENTE");
                    
                    workshopAgendaEntity = await _workshopAgendaRepository.FindByIdAsync(model.Id);
                    
                    if (workshopAgendaEntity == null)
                    {
                        Console.WriteLine($"[SERVICE-DEBUG] WorkshopAgenda não encontrada para o Model.Id: {model.Id}");
                        CreateNotification(DefaultMessages.WorkshopAgendaNotFound);
                        return null;
                    }

                    Console.WriteLine($"[SERVICE-DEBUG] Entidade encontrada. Iniciando atualização manual.");

                    // A lógica de atualização manual (bypass do SetIfDifferent) é mais segura
                    _updateEntityManually(workshopAgendaEntity, model);

                    var entityJson = System.Text.Json.JsonSerializer.Serialize(workshopAgendaEntity);
                    Console.WriteLine($"[SERVICE-DEBUG] Estado da entidade ANTES de UpdateAsync: {entityJson}");

                    await _workshopAgendaRepository.UpdateAsync(workshopAgendaEntity);
                    Console.WriteLine($"[SERVICE-DEBUG] UpdateAsync executado com sucesso.");
                }

                var result = _mapper.Map<WorkshopAgendaViewModel>(workshopAgendaEntity);
                Console.WriteLine($"[SERVICE-DEBUG] Mapeamento concluído. Retornando resultado.");
                
                return result;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[SERVICE ERROR] Exception in RegisterOrUpdate: {ex.Message}");
                CreateNotification($"Erro ao processar agenda: {ex.Message}");
                throw;
            }
        }

        public async Task<bool> RemoveHour(string date)
        {
            try
            {
                Console.WriteLine($"[SERVICE-DEBUG] RemoveHour chamado para data: {date}");
                
                // ✅ _access já está inicializado no construtor
                if (_access == null || string.IsNullOrEmpty(_access.UserId))
                {
                    Console.WriteLine($"[SERVICE-DEBUG] Acesso não autorizado em RemoveHour");
                    CreateNotification("Acesso não autorizado");
                    return false;
                }

                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[SERVICE ERROR] Exception in RemoveHour: {ex.Message}");
                CreateNotification($"Erro ao remover horário: {ex.Message}");
                return false;
            }
        }

        private void _updateEntityManually(WorkshopAgenda existingEntity, WorkshopAgendaViewModel viewModel)
        {
            if (existingEntity == null || viewModel == null) return;

            existingEntity.Sunday = MapDay(viewModel.Sunday);
            existingEntity.Monday = MapDay(viewModel.Monday);
            existingEntity.Tuesday = MapDay(viewModel.Tuesday);
            existingEntity.Wednesday = MapDay(viewModel.Wednesday);
            existingEntity.Thursday = MapDay(viewModel.Thursday);
            existingEntity.Friday = MapDay(viewModel.Friday);
            existingEntity.Saturday = MapDay(viewModel.Saturday);
        }

        private WorkshopAgendaAux MapDay(WorkshopAgendaAuxViewModel dayModel)
        {
            return new WorkshopAgendaAux
            {
                Open = dayModel?.Open ?? false,
                StartTime = dayModel?.StartTime ?? "",
                ClosingTime = dayModel?.ClosingTime ?? "",
                StartOfBreak = dayModel?.StartOfBreak ?? "",
                EndOfBreak = dayModel?.EndOfBreak ?? ""
            };
        }
    }
}
